// Load FFI modules
import "./ffi/tailwind.css";
import "./ffi/dsfr.css";
import "./ffi/dsfr";

// Import publicodes model
import rules, { ui, personas } from "../node_modules/publicodes-voiture";

import * as publicodes from "./ffi/publicodes";
import * as publicodesRulePage from "./web-components/rule-page/define";

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
  rules: publicodes.RawRules,
  situation: publicodes.Situation,
): Promise<publicodes.Engine | undefined> {
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
export const onReady = async ({ app }: { app: any }) => {
  let engine: publicodes.Engine | undefined;

  engine = await safeInitEngine(app, rules, situation);

  const setSituation = (
    app: any,
    newSituation: publicodes.Situation | null,
  ) => {
    localStorage.setItem("situation", JSON.stringify(newSituation ?? {}));
    engine?.setSituation(newSituation ?? {});
    app.ports.onSituationUpdated.send(null);
  };

  if (engine) {
    // Defines the custom component <publicodes-rule-page> to be used in the Elm
    // app to render the React component <RulePage> used for the documentation.
    publicodesRulePage.defineCustomElementWith(engine, app);
  }

  // Subscribes to outgoing messages from Elm and handles them
  if (app.ports && app.ports.outgoing) {
    app.ports.outgoing.subscribe(async ({ tag, data }) => {
      switch (tag) {
        // Publicodes
        case "RESTART_ENGINE": {
          // Try to reinitialize the engine with an empty situation
          engine = await safeInitEngine(app, rules, {});
        }
        case "SET_SITUATION": {
          setSituation(app, data);
          break;
        }
        case "UPDATE_SITUATION": {
          const newSituation = {
            ...engine.getSituation(),
            [data.name]: data.value,
          };
          setSituation(app, newSituation);
          break;
        }
        case "SET_SIMULATION_STEP": {
          localStorage.setItem("simulationStep", data);
          break;
        }
        case "EVALUATE_ALL": {
          if (!engine) {
            return;
          }
          try {
            console.time(`EVALUATE_ALL (${data.length} rules)`);
            const evaluatedRules = data.map((rule: publicodes.RuleName) => {
              const result = engine.evaluate(rule);
              const isApplicable = true;
              // NOTE: maybe checking [result.nodeValue !== null] is enough. If
              // we start to experience performance issues, we can remove the
              // check for [result.nodeValue !== null]
              engine.evaluate({ "est applicable": rule }).nodeValue === true;

              return [
                rule,
                {
                  isApplicable,
                  nodeValue: result.nodeValue ?? null,
                  unit: publicodes.getSerializedUnit(result),
                },
              ];
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
};
