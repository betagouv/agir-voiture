// Load FFI modules
import "./ffi/tailwind.css";
import "./ffi/dsfr.css";
import "./ffi/dsfr";

// Import publicodes model
import rules, { ui, personas } from "publicodes-voiture";

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
    simulationStep: localStorage.getItem("simulationStep") ?? "Start",
  };
}

/**
 * This function is called AFTER the Elm app starts up and is used to
 * receive/send messages to/from Elm via ports.
 */
export const onReady = async ({ app }: { app: any }) => {
  const engine = await publicodes.createAsync(rules, situation);

  publicodesRulePage.defineCustomElementWith(engine, app);

  if (app.ports) {
    //TODO
  }
};
