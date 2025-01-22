// Load FFI modules
import "./ffi/tailwind.css";
import "./ffi/dsfr.css";
import "./ffi/dsfr";

// Import publicodes model
import {
  Alternative,
  CarSimulator,
  RuleName,
  Situation,
} from "@betagouv/publicodes-voiture";
import personas from "@betagouv/publicodes-voiture/personas";
import rules from "@betagouv/publicodes-voiture/rules";

import ui from "./ffi/ui.js";
import * as publicodesRulePage from "./web-components/rule-page/define.js";
import { Rule } from "publicodes";

const situation = JSON.parse(localStorage.getItem("situation") ?? "{}");

/**
 * This function is called BEFORE the Elm app starts up.
 *
 * The value returned here will be passed as flags into your `Shared.init` function.
 */
export function flags() {
  return {
    rules,
    ui,
    personas,
    situation,
    simulationStep: localStorage.getItem("simulationStep") ?? "NotStarted",
  };
}
/**
 * This function is called AFTER the Elm app starts up and is used to
 * receive/send messages to/from Elm via ports.
 */
export const onReady = ({ app }: { app: any }) => {
  safeInitSimulator(app, rules, situation).then((simulator: CarSimulator) => {
    const setSituation = (app: any, newSituation: Situation | null) => {
      localStorage.setItem("situation", JSON.stringify(newSituation ?? {}));
      simulator?.setSituation(newSituation ?? {});
      app.ports.onSituationUpdated.send(null);
    };

    if (simulator) {
      // Defines the custom component <publicodes-rule-page> to be used in the
      // Elm app to render the React component <RulePage> used for the
      // documentation.
      publicodesRulePage.defineCustomElementWith(
        // NOTE: we need to get the ref to the engine to be able to correctly
        // synchronize the situation between the Elm app and the custom
        // element.
        // TODO: to test if it's really necessary.
        simulator.getEngine({ shallowCopy: false }),
        app,
      );
    }

    // Subscribes to outgoing messages from Elm and handles them
    if (app.ports && app.ports.outgoing) {
      app.ports.outgoing.subscribe(async ({ tag, data }) => {
        switch (tag) {
          // Publicodes
          case "RESTART_ENGINE": {
            // Try to reinitialize the engine with an empty situation
            simulator = await safeInitSimulator(app, rules, {});
          }
          case "SET_SITUATION": {
            setSituation(app, data);
            break;
          }
          case "UPDATE_SITUATION": {
            const newSituation = {
              ...simulator.getEngine().getSituation(),
              [data.name]: data.value,
            } as Situation;
            setSituation(app, newSituation);
            break;
          }
          case "SET_SIMULATION_STEP": {
            localStorage.setItem("simulationStep", data);
            break;
          }
          case "EVALUATE_USER_CAR": {
            console.time("[publicodes:evaluateCar]");
            const user = simulator.evaluateCar();
            console.timeEnd("[publicodes:evaluateCar]");
            console.log("User car: ", user);

            app.ports.onEvaluatedUserCar.send(objUndefinedToNull(user));
            break;
          }
          case "EVALUATE_TARGET_CAR": {
            console.time("[publicodes:evaluateTarget]");
            const target = simulator.evaluateTargetCar();
            console.timeEnd("[publicodes:evaluateTarget]");

            app.ports.onEvaluatedTargetCar.send(
              target.hasChargingStation.value === null ||
                target.size.value === null
                ? null
                : objUndefinedToNull(target),
            );
            break;
          }
          case "EVALUATE_ALTERNATIVES": {
            console.time("[publicodes:evaluateAlternatives]");
            const alternatives = simulator.evaluateAlternatives();
            console.timeEnd("[publicodes:evaluateAlternatives]");

            app.ports.onEvaluatedAlternatives.send(
              alternatives.map(objUndefinedToNull),
            );
            break;
          }
          case "EVALUATE_ALL": {
            if (!simulator) {
              return;
            }
            try {
              console.log("startevaluating all rules");
              const evaluatedRules = data.map((rule: RuleName) => {
                const evaluation = Object.fromEntries(
                  Object.entries(simulator.evaluateRule(rule)).map(
                    ([key, value]) => [
                      key,
                      // NOTE: needed to convert undefined to null to be able
                      // to correctly deserialize the value in Elm (maybe a
                      // cleaner solution should be implemented).
                      undefinedToNull(value),
                    ],
                  ),
                );

                return [rule, evaluation];
              });
              app.ports.onEvaluatedRules.send(evaluatedRules);
            } catch (error) {
              app.ports.onEngineError.send(error.message);
            }
            break;
          }

          case "DOWNLOAD_SITUATION": {
            const blob = new Blob(
              [JSON.stringify(simulator.getEngine().getSituation(), null, 2)],
              { type: "application/json" },
            );
            const downloadURL = URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = downloadURL;
            a.download =
              "ma-simulation-pour-mes-options-de-mobilité-durable.json";
            document.body.appendChild(a);
            a.click();
            URL.revokeObjectURL(downloadURL);
            break;
          }

          // Modal dialog
          case "OPEN_MODAL": {
            const dialog = document.getElementById(data) as HTMLDialogElement;
            if (dialog) {
              dialog.showModal();
            } else {
              console.error("Dialog not found: ", data);
            }
            break;
          }
          case "CLOSE_MODAL": {
            const dialog = document.getElementById(data) as HTMLDialogElement;
            if (dialog) {
              dialog.close();
            } else {
              console.error("Dialog not found: ", data);
            }
            break;
          }

          // Common JS functions
          case "SCROLL_TO_TOP": {
            console.log("Scrolling to top");
            window.scrollTo(0, 0);
            break;
          }

          default: {
            console.error("Unknown message from Elm with tag: ", tag);
          }
        }
      });
    }
  });
};

// TODO: it's really beneficial to have the engine initialized asynchronously
// if we await it directly?
async function safeInitSimulator(
  app: any,
  rules: Record<RuleName, Rule>,
  situation: Situation,
): Promise<CarSimulator | undefined> {
  try {
    const simulator = await createAsync(rules, situation);
    app.ports.onEngineInitialized.send(null);
    return simulator;
  } catch (error) {
    app.ports.onEngineError.send(error.message);
  }
}

/**
 * Instantiate a new publicodes engine with the given rules and situation.
 *
 * NOTE: I encapsulate the engine in a promise to be able to
 * initialize it asynchronously. This is useful to avoid blocking the UI while
 * the engine is being initialized.
 *
 * TODO: a better error handling should be implemented.
 *
 * FIXME: situation shouldn't be nullable, investigation needed.
 */
export function createAsync(
  rules: Readonly<Record<RuleName, Rule>>,
  situation: Readonly<Situation> | null,
) {
  return new Promise<CarSimulator>((resolve) => {
    const nbRules = Object.keys(rules).length;
    console.time(`[publicodes:parsing] ${nbRules} rules`);
    const simulator = new CarSimulator();
    simulator.setSituation(situation ?? {});
    console.timeEnd(`[publicodes:parsing] ${nbRules} rules`);
    resolve(simulator);
  });
}

/**
 * In elm, only `null` value are allowed in JSON. This function is used to
 * convert `undefined` to `null` in order to be able to correctly deserialize
 * the value in Elm.
 */
function undefinedToNull<T>(value: T | undefined): T | null {
  return value ?? null;
}

/**
 * TODO: recursivelly convert all undefined values to null in an object.
 *
 * PERF: this function could be seen as a performance bottleneck but the
 * performance impact is negligible (max 1ms by rules).
 */
function objUndefinedToNull(obj: object): object {
  const res = Object.fromEntries(
    Object.entries(obj).map(([key, value]) => [key, undefinedToNull(value)]),
  );
  return res;
}
