import Engine, { Rule, Situation as PublicodesSituation } from "publicodes";

export type RuleName = string;
export type PublicodeValue = string | number;
export type RawRule = Omit<Rule, "nom"> | string | number;
export type Situation = PublicodesSituation<RuleName>;

/**
 * Instantiate a new publicodes engine with the given rules and situation.
 *
 * NOTE: I encapsulate the engine in a promise to be able to
 * initialize it asynchronously. This is useful to avoid blocking the UI while
 * the engine is being initialized.
 *
 * TODO: Handle errors
 */
export function createAsync(
  rules: Readonly<Record<RuleName, RawRule>>,
  situation: Readonly<Situation>,
) {
  return new Promise<Engine>((resolve) => {
    const nbRules = Object.keys(rules).length;
    console.time(`[publicodes:parsing] ${nbRules} rules`);
    const engine = new Engine(rules).setSituation(situation);
    console.timeEnd(`[publicodes:parsing] ${nbRules} rules`);
    resolve(engine);
  });
}
