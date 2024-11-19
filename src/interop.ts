// Load FFI modules
import "./ffi/tailwind.css";
import "./ffi/dsfr.css";
import "./ffi/dsfr";

// Import publicodes model
import {
  CarSimulatorEngine,
  RuleName,
  Situation,
} from "@betagouv/publicodes-voiture";
import personas from "@betagouv/publicodes-voiture/personas";
import rules from "@betagouv/publicodes-voiture/rules";

import ui from "./ffi/ui.js";
import * as publicodes from "./ffi/publicodes.js";
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

// TODO: it's really beneficial to have the engine initialized asynchronously
// if we await it directly?
async function safeInitEngine(
  app: any,
  rules: Record<RuleName, Rule>,
  situation: Situation,
): Promise<CarSimulatorEngine | undefined> {
  try {
    const engine = await publicodes.createAsync(rules, situation);
    app.ports.onEngineInitialized.send(null);
    return engine;
  } catch (error) {
    app.ports.onEngineError.send(error.message);
  }
}

/**
 * This function is called AFTER the Elm app starts up and is used to
 * receive/send messages to/from Elm via ports.
 */
export const onReady = ({ app }: { app: any }) => {
  safeInitEngine(app, rules, situation).then(
    (simulatorEngine: CarSimulatorEngine) => {
      const setSituation = (app: any, newSituation: Situation | null) => {
        localStorage.setItem("situation", JSON.stringify(newSituation ?? {}));
        simulatorEngine?.setSituation(newSituation ?? {});
        app.ports.onSituationUpdated.send(null);
      };

      if (simulatorEngine) {
        // Defines the custom component <publicodes-rule-page> to be used in the
        // Elm app to render the React component <RulePage> used for the
        // documentation.
        publicodesRulePage.defineCustomElementWith(
          // NOTE: we need to get the ref to the engine to be able to correctly
          // synchronize the situation between the Elm app and the custom
          // element.
          // TODO: to test if it's really necessary.
          simulatorEngine.getEngine({ shallowCopy: false }),
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
              simulatorEngine = await safeInitEngine(app, rules, {});
            }
            case "SET_SITUATION": {
              setSituation(app, data);
              break;
            }
            case "UPDATE_SITUATION": {
              const newSituation = {
                ...simulatorEngine.getEngine().getSituation(),
                [data.name]: data.value,
              } as Situation;
              setSituation(app, newSituation);
              break;
            }
            case "SET_SIMULATION_STEP": {
              localStorage.setItem("simulationStep", data);
              break;
            }
            case "EVALUATE_RESULTS": {
              const user = simulatorEngine.evaluateCar();
              const alternatives = simulatorEngine.evaluateAlternatives();
              console.log("alternatives", alternatives);
              app.ports.onEvaluatedResults.send({ user, alternatives });
              break;
            }
            case "EVALUATE_ALL": {
              if (!simulatorEngine) {
                return;
              }
              try {
                console.time(`EVALUATE_ALL (${data.length} rules)`);
                const evaluatedRules = data.map((rule: RuleName) => {
                  const evaluation = Object.fromEntries(
                    Object.entries(simulatorEngine.evaluateRule(rule)).map(
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
                console.timeEnd(`EVALUATE_ALL (${data.length} rules)`);
                app.ports.onEvaluatedRules.send(evaluatedRules);
              } catch (error) {
                app.ports.onEngineError.send(error.message);
              }
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
    },
  );
};

function undefinedToNull<T>(value: T | undefined): T | null {
  return value ?? null;
}
