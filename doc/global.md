# Réflexions générale sur la conception

## Comparaison 1 vs 1

Est-ce qu'il ne faudrait pas rajouter la possibilité de faire une comparaison
entre un ou deux modèles précis de véhicules. L'utilisateur:ice pourrait
simplement remplir la première série de questions en fonction des informations
trouvées en ligne (ex: L'argus) sur le modèle envisagée. Ce qui permettrait une
comparaison plus précise et également de pouvoir récupérer les informations
nécessaires (masse, prix, indice écologique) pour le calcul du bonus
écologique.

## Signifier les désavantages des véhicules thermiques (malus écologique, crit'air, interdictions, etc...)

En plus de se focaliser sur les aides à l'achat il serait peut-être également
utile d'avoir des informations sur les types de véhicules qui vont être
interdits ou bien qui seront soumis à des malus.

### Calcul du malus écologique

Le calcul du malus écologique nécessite d'avoir des informations précise sur le
véhicule (ex: émission de CO2) et n'est donc _a priori_ pas estimable pour les
alternatives actuelles.

## Limite de la modélisation du bonus écologique

Après une première tentative de modélisation, les paramètres nécessaire pour
déterminer l’éligibilité à l’aide semblent trop précis pour être inférés
automatiquement pour chacune des alternatives (achat voiture neuve). En effet,
pour déterminer si une voiture est éligible au bonus écologique, il faut
connaitre entre autre :

- **sa masse** (< 2,4 tonnes)
  Elle pourrait être inférée à partir du gabarit comme c’est le cas pour le
  [calcul de l’empreinte
  carbone](https://agir-voiture.netlify.app/documentation/ngc/transport/voiture/gabarit/berline/poids).
  Cependant, utiliser une masse moyenne en fonction du gabarit pourrait induire
  en erreur en incluant des voitures ayant potentiellement une masse supérieur à
  2,4 tonnes car dans le modèle de NGC le poids d’un SUV est approximé à 2
  tonnes.
- **son prix** (< 47 000 €)
  Tout comme la masse, le prix est estimé en fonction du gabarit et de la
  motorisation. Cependant, ce paramètre peut grandement varier entre deux
  véhicules d’un même gabarit avec la même motorisation.
- **son score environnemental**
  Ce paramètre n’est pas estimable à partir des informations actuelles. Il
  faudrait être en mesure de pouvoir le déterminer à partir de
  [https://score-environnemental-bonus.ademe.fr/](https://score-environnemental-bonus.ademe.fr/)

La nécessité d’avoir ces informations remet une bille dans le fait d’utiliser
CarLabelling pour récupérer les informations à partir d’un modèle de véhicule,
avec les limites suivantes :

- Liste non-exaustive (je sais pas à quel point)
- Ne semble plus être maintenu
- Le calcul du bonus-malus semble ne plus être à jour avec les dernière
  modifications. Cependant, nous pourrions recalculer cette valeur nous même à
  partir des autres informations.
- Incohérence dans les données avec doublons, difficile de déterminer quelle
  modèle considérer comme alternative.
- Problème de perf pour calculer tel quel toutes les alternatives.
- Prix probablement plus d’actualité

Une solution consisterait à utiliser une autre BD, malheureusement elles
semblent toutes payantes.

On pourrait dans un premier temps partir du principe que n’importe quelle
voiture électrique est élligible et simplement faire varier le montant du bonus
en fonction du RFRPP.

---

https://www.economie.gouv.fr/particuliers/bonus-ecologique

https://www.fueleconomy.gov/
