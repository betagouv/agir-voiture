/**
 * Define the UI layout (i.e the order of questions to ask to the user and the
 * categories to group them).
 *
 * @note This is defined in a TypeScript file to be able to typecheck the rule
 * names of the questions.
 */

import { Questions, RuleName } from "@betagouv/publicodes-voiture";

/**
 * The categories of questions to ask to the user.
 *
 * Each category corresponds to a rule in the publicodes model as its
 * description is used to display help text to the user.
 *
 * The index is used to order the categories in the UI.
 */
const CATEGORIES = {
  voiture: {
    index: 0,
  },
  usage: {
    index: 1,
  },
  "voiture . cible": {
    index: 2,
  },
} as const satisfies Partial<Record<RuleName, { index: number }>>;

// TODO: a check should be added to show warnings if a question is not listed
// in the QUESTIONS object.
const QUESTIONS_ORDER: Partial<
  Record<keyof typeof CATEGORIES, Array<keyof Questions>>
> = {
  voiture: [
    "voiture . occasion",
    "voiture . gabarit",
    "voiture . durée de détention totale",
    "voiture . année de fabrication",
    "voiture . prix d'achat",
    "voiture . motorisation",
    "voiture . thermique . carburant",
    "voiture . thermique . consommation carburant",
    "voiture . thermique . prix carburant",
    "voiture . électrique . consommation électricité",
    "voiture . électrique . prix kWh",
    "coûts . coûts de possession . entretien",
    "coûts . coûts de possession . assurance",
  ],
  usage: [
    "usage . km annuels . connus",
    "usage . km annuels . renseignés",
    "usage . km annuels . calculés . quotidien",
    "usage . km annuels . calculés . vacances",
    "coûts . coûts d'utilisation . stationnement",
    "coûts . coûts d'utilisation . péage",
    "coûts . coûts d'utilisation . contraventions",
  ],
  "voiture . cible": [
    "voiture . cible . achat envisagé",
    "voiture . cible . gabarit",
    "voiture . cible . borne de recharge",
  ],
};

export default {
  categories: CATEGORIES,
  questions: QUESTIONS_ORDER,
};
