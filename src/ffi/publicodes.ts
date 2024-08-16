import PublicodesEngine, {
  Rule,
  Situation as PublicodesSituation,
} from "publicodes";

export type RuleName = string;
export type PublicodeValue = string | number;
export type RawRule = Omit<Rule, "nom"> | string | number;
export type RawRules = Readonly<Record<RuleName, RawRule>>;
export type Situation = PublicodesSituation<RuleName>;
export type Engine = PublicodesEngine<RuleName>;

/**
 * Instantiate a new publicodes engine with the given rules and situation.
 *
 * NOTE: I encapsulate the engine in a promise to be able to
 * initialize it asynchronously. This is useful to avoid blocking the UI while
 * the engine is being initialized.
 *
 * FIXME: situation shouldn't be nullable, investigation needed.
 */
export function createAsync(
  rules: Readonly<RawRules>,
  situation: Readonly<Situation> | null,
) {
  return new Promise<PublicodesEngine>((resolve) => {
    const nbRules = Object.keys(rules).length;
    console.time(`[publicodes:parsing] ${nbRules} rules`);
    const engine = new PublicodesEngine(rules).setSituation(situation ?? {});
    console.timeEnd(`[publicodes:parsing] ${nbRules} rules`);
    resolve(engine);
  });
}
