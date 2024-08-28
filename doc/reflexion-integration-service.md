# Méthode d'intégration des services externes (WIP)

Emile Rolley | Août 2024

---

Ce document de travail **en cours de construction** à pour objectif d'entamer
une réflexion sur une méthode générale d'intégration des services externes (si
cela est possible) dans Agir en prenant comme cas pratique l'intégration du
simulateur _Quel véhicule pour remplacer le mien ?_.

## Définitions

Voici quelques définitions permettant de préciser les termes employés dans le
document :

**Données** : ensemble des informations manipulés et échangés (résultats de
calculs, identifiants, etc...).

**Situation** : donnée particulière représentant les réponses de
l'utilisateurice par un ensemble de couple clé/valeur.

**Service** : brique logiciel avec laquelle il possible d'interagir pour
transformer des données.

**Service externe** : fait référence à un service indépendant d'Agir qui est
cependant accessible depuis Agir directement que ce soit via une simple
redirection ou une intégration complète.

**Serveur Agir** : fait référence au serveur d'Agir qui s'occupe de traiter et
stocker les données.

**Client Agir** : fait référence au site web et à l'application mobile d'Agir,
demande et affiche les données récupérées depuis le serveur Agir ou bien depuis
d'autres services _complètement_ externalisés. (Il semblerait que cela passe
quand même par le serveur et que ce soit lui qui s'occupe de récupérer les
données au près des services externes ? @wojciech.)

**API (_Application Programming Interface_)** : fait référence à l'interface d'un
service.

**_Framework_** : ensemble de pratiques et de briques logiciels définis dans le
but de faciliter et standardiser la construction d'un logiciel/composant dans
un contexte donné.

**Modèle de calcul (Publicodes)** : fait référence à un ensemble de règles
rédigées dans le langage [Publicodes](https://publi.codes) permettant de
modéliser un domaine métier et de l'évaluer.

## Problématique

Agir a pour objectif de regrouper un certain nombre de services externes
considérés comme apportant une-plus-value d'information pour l'utilisateurice,
en utilisant la situation connue par Agir pour pré-remplir la situation
nécessaire par le service externe pour fonctionner et ainsi éviter à
l'utilisateurice de devoir renseigner plusieurs fois la même information.

Actuellement il existe plusieurs degrés d'intégration des services externes :

- **Complètement externalisé** : simple redirection, le pont se fait via l'aide
  d'un lien statique.
  > Exemple : _Je change ma voiture_, les aides non intégrées ?
- **Intégration client** : la visualisation des données est faite au niveau des
  clients Agir mais la récupération est faites grâce à une API tierce
  appartenant probablement au service externe à intégrer.
  > Exemple : _Fruits et légumes de saisons_, _Mes commerces proximité_ et à terme
  > _Recettes saines et équilibrées_.
- **Intégration complète** : la visualisation ainsi que la récupération des
  données est effectué par Agir.
  > Exemple : _Nos Gestes Climat_, _Aides vélos_ et _Aides retrofit_.

En vu de l'intégration de nouveaux services externes (tel que le simulateur
_Quel véhicule pour remplacer le mien ?_), **il semble judicieux de définir
_framework_ facilitant l'intégration et la maintenance des futurs services**.

## Cas d'étude : intégration du service externe _Quel véhicule pour remplacer le mien ?_

Ce service est composé de deux parties :

- un [client](https://github.com/betagouv/agir-voiture) permettant de :
  - récupérer la situation de l'utilisateurice via un formulaire
  - utiliser le modèle de calcul avec cette situation
  - mettre en avant les alternatives les plus pertinentes pour cette situation
    donnée
- un modèle de calcul
  ([`publicodes-voiture`](https://github.com/betagouv/publicodes-voiture)) rédigé
  en [Publicodes](https://publi.codes), permettant de calculer l'empreinte
  carbone et le coût du véhicule correspondant à la situation ainsi que des
  différentes alternatives.

> **A noter** : bien que la logique liée au calcul soit isolée dans le modèle
> Publicodes, tout _se passe_ au niveau du client.

L'enjeu de cette section est donc de **présenter les différentes approches
possibles pour intégrer ce service externe**, en essayant de d'anticiper les
contraintes de chacune au niveau de la complexité de l'intégration, de la
maintenance ainsi que de l'expérience utilisateurice.

Permettant ainsi potentiellement pouvoir **faire émerger une approche
généralisable** pour tout service externe (_a minima_ pour une classe).

### Contraintes sur l'intégration

Pour intégrer ce service il faut un moyen de collecter au près de
l'utilisateurice la situation nécessaire pour le calcul : c'est-à-dire, créer
un formulaire côté client.
Puis de récupérer les valeures du résultat en fonction de cette situation.

### Approche n°1 : Situation encodée dans l'URL

Le service est externalisé et la redirection est faite via un lien dynamique
dans lequel la situation est stockée. Le client du service peut ainsi récupérer
les informations stockées dans l'url et pré-remplir les questions.

**Avantages**

L'avantage de cette approche réside dans la **simplicité d'implémentation**.
Il y a simplement besoin de se **mettre d'accord sur la situation à transmettre**.
Cela pourrait se faire en détaillant dans chaque notes de versions du service
externes les clés de la situation utilisée avec le format attendue ainsi que sa
sémantique.

**Inconvénients**

En revanche, l'utilisateurice et **redirigée vers un site externe** ce qui ne pose
pas dans de problème pour le client web mais pour mobile cela pourrait être
plus problématique.

De plus, avec cette méthode, **Agir ne serait pas en capacité de récupéré la
situation complétée par l'utilisateurice** dans le service externe à moins
d'implémenter un pont retour pour envoyer la situation mise à jours à Agir.

### Approche n°2 : Intégration dans les clients Agir

Le service propose une API qui est utilisée par Agir pour récupérer les données
à transmettre et les traitées si besoin avant de les envoyer aux clients Agir
qui les intègrent dans leur vue.

**Avantages**

Cette approche **permet une intégration plus fine et cohérente** de l'interface
du service, avec la **possibilité de la personnaliser**. De plus, Agir **garde
la main sur la situation renseignée** par l'utilisateurice.

**Inconvénients**

La personnalisation de l'interface implique en revanche de devoir **concevoir
et implémenter une nouvelle interface** et cela pour chaque clients.
Cette approche nécessite également d'**implémenter et maintenir une API** pour
le service externe.

### Approche n°3 : Intégration complète

Le calcul est fait directement par le serveur Agir en utilisant le modèle de
calcul Publicodes et les clients Agir intègrent le résultat dans leur vue.

**Avantages**

Comme pour la deuxième approche, cette méthode permet une **intégration
personnalisée** de l'interface du service tout en **gardant la main sur les
données renseignées** par l'utilisateurice. Le tout **sans avoir à implémenter
et maintenir une nouvelle API**.

**Inconvénients**

Nécessite d'**implémenter les différentes intégrations au niveau des clients
Agir**. De plus, cette méthode implique **un suivi régulier des mises à jours**
du modèle de la part de l'équipe d'Agir. La généralisation de cette méthode
pour d'autres services externes pourrait entrainer une **augmentation
significative des dépendances du serveur Agir**.

### Conclusion

**En terme de simplicité la première approche semble de loin la meilleure**. Elle a
cependant, une forte contrainte sur l'expérience utilisateurice et il
semblerait (à confirmer ensemble) qu'elle ne corresponde pas à la vision
d'Agir.

Ainsi, si l'on **souhaite garder une personnalisation de l'interface** en intégrant
le service directement dans les clients Agir, **la troisième méthode semble la
plus adaptée** pour ce service car elle évite de devoir maintenir une brique
logicielle uniquement pour Agir.

Cependant, si pour ce service la troisième méthode semble être la plus
pertinente, **elle n'est généralisable que pour les services externes utilisant
un modèle de calcul abstrait dans un paquet indépendant**.

---

## Définition d'un _framework_ général ?

_A priori_ il y a au moins **deux classes de services externes** qui se dessinent :

- d'une part, les services externes ayant **abstrait leur logique métier** dans une
  brique logicielle réutilisable et indépendante de l'interface du service. Les
  modèles Publicodes en sont un bon exemple (et peut-être le seul actuellement
  pour Agir).
- d'autre part, les services externes dont il est **uniquement possible
  d'interagir avec leur logique métier via une API**.

La troisième approche explicité plus haut n'est donc pas réalisable pour les
services de la deuxième classe.
En revanche, pour les services de la première classe, il est envisageable
d'implémenter une API indépendante autour de cette brique logicielle et laisser
entrevoir la possibilité d'un _framework_ général.

### Note sur Publicodes

L'objectif de Publicodes est de pouvoir facilement abstraire et isoler la
logique métier (tout en permettant une transparence du calcul grâce à une
documentation interactive et faciliter la contribution de personnes non-dev).

#### Créer un simulateur à partir d'un modèle Publicodes

Actuellement, une dizaine de modèles Publicodes ont été
[publiés](https://publi.codes/bibliotheque). Et chaque service les utilisant
ont quasiment tous leur façon faire.

En effet, il existe plusieurs approche pour créer un formulaire à partir d'un
modèle Publicodes :

**1. À partir des dépendances d'une règle**

Il est facile de récupérer à partir de la règle que l'on souhaite évaluer,
toutes les règles qui sont nécessaire pour son calcul et qui n'ont pas été
renseignées par l'utilisateurice. C'est la méthode qui est décrite dans la
[documentation](https://publi.codes/docs/guides/creer-formulaire).

L'avantage de cette méthode est qu'elle permet d'avoir une interface qui
s'adapte automatiquement à une modification du modèle et maintient ainsi une
séparation forte entre le domaine métier et l'UI.

**2. En explicitant les questions à poser**

Une deuxième approche qui est utilisé pour le modèle de
[`publicodes-evenements`](https://github.com/ekofest/publicodes-evenements) et
de [`publicodes-voiture`](https://github.com/betagouv/publicodes-voiture)
consiste à exposer en plus des règles Publicodes, un objet
[`ui`](https://github.com/betagouv/publicodes-voiture/blob/main/ui.yaml)
décrivant les règles correspondantes aux questions à afficher ainsi que l'ordre
dans lequel les poser.

Cette méthode permet de pouvoir facilement décrire les questions à afficher
sans devoir créer une heuristique dans le client pour déterminer l'ordre des
questions et évite aussi que la façon dont on souhaite afficher les questions
impacte la modélisation.

Le fait de définir explicitement les questions à posée, c'est-à-dire les
entrées d'un modèle semble être une piste pour créer une _interface commune_
entre les services.

### Définition d'une interface commune (et génération automatisée de formulaire ?)

Dans l'idéal, il faudrait avoir un système qui permette d'abstraire au serveur
Agir toute la logique métier du service externe à intégrer.

Pour cela le serveur Agir a besoin de pouvoir :

1. récupérer les données nécessaires au fonctionnement du service
2. les enrichir avec la situation de l'utilisateurice connue par le serveur
3. envoyer aux clients cette informations
4. récupérer les informations renseignées par l'utilisateurice au près des
   clients
5. mettre à jours la situation persistante
6. récupérer au près du service les résultats correspondant à la situation
   fournie
7. envoyer les résultats aux clients qui les restituent à l'utilisateurice

#### Les données attendues

Un [JSON Schema](https://json-schema.org/) pourrait être utilisé pour décrire
les informations attendues.

> C'est cette méthode qui est utilisée pour
> [`catala-dsfr`](https://github.com/CatalaLang/catala-dsfr) qui est ainsi
> capable de générer automatiquement simulateur pour tout programme
> [Catala](https://catala-lang.org). Pour un exemple de schema, voir les assets
> de
> [`catala-web-assets`](https://github.com/CatalaLang/catala-web-assets/blob/main/assets/).

#### Correspondance des données

Une **difficulté apparait pour établir un isomorphisme entre les clés des
différentes situations**.

En effet, on peut facilement imaginer un service ayant besoin du nombre de km
parcourus par un.e utilisateurice qu'il appel `km annuels` alors que dans la
situation sauvegardée par le serveur cette même information correspond à la clé
`km parcourus à l'année`. De même que pour les énumérations comme pour le
gabarit d'une voiture par exemple, les valeurs utilisées ne sont pas les mêmes
et ainsi avoir un service qui utilise `monospace` et l'autre `moyenne`.

Pour pallier à ce problème il faudrait avoir un standard décrivant la situation
sauvegardée par Agir et forcer ainsi **les services externes à _mapper_ leurs
données pour correspondre à la situation de référence d'Agir**.

> La _situation de référence_ semble correspondre au _KYC_ du serveur Agir ?
> @wojciech

Pour les services _intégrés totalement_, cela ne poserait pas de problème. En
revanche, pour les autres services cela **pourrait être à la charge de l'équipe
d'Agir d'implémenter et de maintenir ces _wrappers_**.

Se pose également la question de comment intégrer les nouvelles clés pas encore
sauvegarder dans la situation de référence d'Agir. **Ce sera à l'équipe d'Agir de
décider parmi la situation demandée par le service externe de quelles clés
ajouter dans la situation de référence et dans quel format ?**

Une autre possibilité pourrait être de considérer que le **serveur Agir accepte
uniquement des données correspondant à la situation de référence** et ainsi
potentiellement forcer le service externe à s'adapter et peut-être proposer une
version simplifié ne dépendant uniquement des données issues de la situation de
références.

#### Les résultats

La principale contrainte sur les résultats et de **savoir à l'avance le type
retourné** pour que les clients puissent les intégrer comme ils le souhaitent dans
leur vues.

Cependant, il est possible qu'une partie des résultats retournés puissent être
utile à sauvegarder dans la situation de référence ?

### Maintenance des modèles Publicodes

Actuellement, Agir utilise plusieurs modèles Publicodes qui ne sont pas publiés et
sauvegardés dans un unique fichier JSON :

- [Aides Vélos](https://github.com/betagouv/agir-back/blob/a0cc00664ad9782bc8ee3536dae82563300313d9/src/infrastructure/data/aidesVelo.json)
- [Aides Retrofits](https://github.com/betagouv/agir-back/blob/a0cc00664ad9782bc8ee3536dae82563300313d9/src/infrastructure/data/aidesRetrofit.json)

Il serait important de pouvoir les publiés indépendamment et dans des fichiers
Publicodes afin que les modifications faites aux modèles puissent servir au
plus grand nombre et faciliter les contributions externes : **comme par exemple
pouvoir embarquer les collectivités directement dans la mise à jours de leurs
aides** et ainsi éviter d'avoir recours à des modèles statistiques pour le
faire à leur place.

Cela pose une seconde question sur la maintenance des modèle publiés par des
équipes externes, comme c'est le cas pour Nos Gestes Climat. Actuellement, la
version utilisée est la `2.5.2` or la `3.0.0` est actuellement disponible avec
une nouvelle métrique : l'empreinte hydrique.
**Qui s'occupe de mettre à jours ces modèles, maintenir les contributions
externes, etc... ? Et sous quelle temporalité ?**
