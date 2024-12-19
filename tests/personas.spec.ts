import { test, expect, Page } from "@playwright/test";
import personas from "@betagouv/publicodes-voiture/personas";
import rules from "@betagouv/publicodes-voiture/rules";
import { Persona, Situation } from "@betagouv/publicodes-voiture";

test.describe("Simulate personas", () => {
  Object.values(personas).forEach((persona: Persona) => {
    test(persona.titre, async ({ page }) => {
      await page.goto("/");
      expect(await page.title()).toEqual(
        "Accueil - Mes options de mobilité durable - J'agis",
      );
      await page.click('text="Démarrer"');
      expect(page.url()).toMatch(/.*\/simulateur/);

      await expect(page.getByRole("heading")).toHaveText(
        "Informations sur la voiture",
      );
      await fillInputsWith(page, persona.situation);
      await page.getByRole("button", { name: "Suivant" }).click();

      await expect(page.getByRole("heading")).toHaveText("Usage de la voiture");
      await fillInputsWith(page, persona.situation);
      await page.getByRole("button", { name: "Suivant" }).click();

      await expect(page.getByRole("heading")).toHaveText("Voiture envisagée");
      await fillInputsWith(page, persona.situation);
      await page.getByRole("button", { name: "Voir le résultat" }).click();

      await expect(page.getByRole("heading").first()).toHaveText(
        "Récapitulatif de votre situation",
      );
      await expect(page.locator("#user-car-cost")).toHaveText(
        Math.round(persona.coûts).toLocaleString("fr-FR") + "€",
      );
      await expect(page.locator("#user-car-emissions")).toHaveText(
        Math.round(persona.empreinte).toLocaleString("fr-FR") + "kgCO2e",
      );
    });
  });
});

async function fillInputsWith(page: Page, situation: Situation) {
  const alreadyFilled = [];
  let changed = true;

  // NOTE: we need to try multiple times to fill the inputs because some of the
  // questions are dynamically asked based on the previous answers.
  while (changed) {
    changed = false;
    await page.waitForTimeout(500);
    for (const ruleName in situation) {
      if (alreadyFilled.includes(ruleName)) {
        continue;
      }

      const value = situation[ruleName];
      const question = rules[ruleName].question;

      if (typeof value === "number") {
        const input = page.getByLabel(question);

        if (await input.isVisible()) {
          await input.fill(value.toString());

          alreadyFilled.push(ruleName);
          changed = true;
        }
      } else if (value === "oui" || value === "non") {
        for (const radio of await page.getByRole("radio").all()) {
          await expect(radio).toHaveAttribute("id");

          const id = await radio.getAttribute("id");
          const ruleName = id.slice(
            "radio-".length,
            id.length - "-option-Oui".length,
          );
          const value = id.endsWith("-option-Oui") ? "oui" : "non";
          if (
            ruleName in situation &&
            !alreadyFilled.includes(ruleName) &&
            situation[ruleName] === value
          ) {
            await radio.click({ force: true });

            alreadyFilled.push(ruleName);
            changed = true;
          }
        }
      } else {
        const select = page.getByLabel(question);

        if (await select.isVisible()) {
          const publicodesValue = situation[ruleName];
          const value = publicodesValue.slice(1, publicodesValue.length - 1);

          await select.selectOption({ value });

          alreadyFilled.push(ruleName);
          changed = true;
        }
      }
    }
  }
}
