import {
  CarSimulatorEngine,
  RuleName,
  Situation,
} from "@betagouv/publicodes-voiture";
import { serializeUnit, EvaluatedNode, Rule } from "publicodes";

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
  return new Promise<CarSimulatorEngine>((resolve) => {
    const nbRules = Object.keys(rules).length;
    console.time(`[publicodes:parsing] ${nbRules} rules`);
    const engine = new CarSimulatorEngine();
    engine.setSituation(situation ?? {});
    console.timeEnd(`[publicodes:parsing] ${nbRules} rules`);
    resolve(engine);
  });
}

/**
 * Returns the formatted unit of the given node value if it exists.
 */
export function getSerializedUnit(nodeValue: EvaluatedNode): string | null {
  if (nodeValue?.unit) {
    return serializeUnit(nodeValue?.unit);
  }
  return null;
}
