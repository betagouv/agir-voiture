module Components.Simulateur.Results exposing (Config, view)

import BetaGouv.DSFR.Accordion as Accordion
import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.CallOut as CallOut
import BetaGouv.DSFR.Icons as Icons
import Components.DSFR.Card as Card
import Components.LoadingCard
import Components.Simulateur.ComparisonTable
import Components.Simulateur.Navigation
import Components.Simulateur.TotalCard as TotalCard
import Components.Simulateur.UserTotal
import Core.Evaluation exposing (Evaluation)
import Core.Results.CarInfos exposing (CarInfos)
import Core.Results.RuleValue as RuleValue exposing (RuleValue)
import Core.Results.TargetInfos exposing (TargetInfos)
import Core.UI as UI
import Dict exposing (Dict)
import Html exposing (Html, a, div, h2, h3, p, section, span, text)
import Html.Attributes exposing (class, href, target)
import Html.Extra exposing (viewMaybe)
import Publicodes exposing (RawRules)
import Publicodes.RuleName exposing (RuleName)
import Shared.EngineStatus as EngineStatus exposing (EngineStatus)
import Shared.SimulationStep exposing (SimulationStep)


type alias Config msg =
    { categories : List UI.Category
    , onNewStep : SimulationStep -> msg
    , evaluations : Dict RuleName Evaluation
    , rules : RawRules
    , userCar : Maybe CarInfos
    , alternatives : Maybe (List CarInfos)
    , targetInfos : Maybe TargetInfos
    , engineStatus : EngineStatus
    , accordionsState : Dict String Bool
    , onToggleAccordion : String -> msg
    }


accordionCarbonId : String
accordionCarbonId =
    "accordion-carbon"


accordionComparisonTableId : String
accordionComparisonTableId =
    "accordion-comparison-table"


view : Config msg -> Html msg
view props =
    let
        sortedAlternativesOn attr =
            props.alternatives
                |> Maybe.withDefault []
                |> List.sortWith
                    (\a b -> Basics.compare (attr a).value (attr b).value)

        alternativesSortedOnCost =
            sortedAlternativesOn .cost

        alternativesSortedOnEmission =
            sortedAlternativesOn .emissions

        cheapest =
            List.head alternativesSortedOnCost

        greenest =
            List.head alternativesSortedOnEmission

        viewAlternative :
            (CarInfos -> RuleValue comparable)
            -> TotalCard.KindTag
            -> CarInfos
            -> Html msg
        viewAlternative attr tag infos =
            case ( props.engineStatus, props.userCar ) of
                ( EngineStatus.Done, Just user ) ->
                    let
                        alternativeIsBetter =
                            (user.size /= infos.size)
                                || (Basics.compare (attr user).value (attr infos).value == GT)
                    in
                    div []
                        [ if alternativeIsBetter then
                            TotalCard.new
                                { -- TODO: better id
                                  id = "alternative-" ++ RuleValue.title infos.size ++ "-" ++ RuleValue.title infos.motorisation ++ (Maybe.map RuleValue.title infos.fuel |> Maybe.withDefault "")
                                , title = Maybe.withDefault "" infos.title
                                , cost = infos.cost.value
                                , emission = infos.emissions.value
                                }
                                |> -- NOTE: maybe not relevant as information is already in the title
                                   TotalCard.withContext
                                    ([ RuleValue.title infos.size
                                     , RuleValue.title infos.motorisation
                                     , infos.fuel
                                        |> Maybe.map RuleValue.title
                                        |> Maybe.withDefault ""
                                     ]
                                        |> List.filterMap
                                            (\value ->
                                                if String.isEmpty value then
                                                    Nothing

                                                else
                                                    Just { value = value, unit = Nothing }
                                            )
                                    )
                                |> TotalCard.withComparison
                                    { costToCompare = user.cost.value
                                    , emissionToCompare = user.emissions.value
                                    }
                                |> TotalCard.withTag tag
                                |> TotalCard.view

                          else
                            div [ class "flex gap-2 items-center font-medium rounded-md fr-my-4v fr-p-4v outline outline-1 outline-[var(--border-plain-success)] text-[var(--text-default-success)]" ]
                                [ Icons.iconMD Icons.system.successLine
                                , case tag of
                                    TotalCard.Cheapest ->
                                        text "Votre voiture est déjà la moins chère !"

                                    TotalCard.Greenest ->
                                        text "Votre voiture est déjà la plus écologique !"

                                    _ ->
                                        text "Vous avez déjà la meilleure alternative !"
                                ]
                        ]

                _ ->
                    Components.LoadingCard.view

        viewAlternatives args =
            section []
                [ h2 [] args.title
                , p [ class "fr-col-8" ] args.desc
                , div [ class "grid grid-cols-2 gap-12" ]
                    (case ( args.cheapest, args.greenest ) of
                        ( Just cheapestAlternative, Just greenestAlternative ) ->
                            [ viewAlternative .cost TotalCard.Cheapest cheapestAlternative
                            , viewAlternative .emissions TotalCard.Greenest greenestAlternative
                            ]

                        _ ->
                            [ Components.LoadingCard.view, Components.LoadingCard.view ]
                    )
                ]

        viewAlternativesSection { size, hasChargingStation } =
            let
                -- Filters the alternatives results on the given target (size, charging station)
                filterInTarget : List CarInfos -> List CarInfos
                filterInTarget =
                    case props.targetInfos of
                        Nothing ->
                            identity

                        Just target ->
                            List.filter
                                (\carInfo ->
                                    -- Only keep the results with the same target gabarit
                                    -- TODO: use a +1/-1 comparison to be more flexible?
                                    let
                                        sameSize =
                                            target.size == carInfo.size

                                        elecAndHasChargingStation =
                                            target.hasChargingStation.value || carInfo.motorisation.value /= "électrique"
                                    in
                                    -- Only keep the results with a charging station if the user has an electric car
                                    sameSize && elecAndHasChargingStation
                                )

                targetCheapest =
                    alternativesSortedOnCost
                        |> filterInTarget
                        |> List.head

                targetGreenest =
                    alternativesSortedOnEmission
                        |> filterInTarget
                        |> List.head
            in
            section [ class "flex flex-col md:gap-20" ]
                [ viewAlternatives
                    { title =
                        [ text "Les meilleures alternatives pour le gabarit "
                        , span [ class "text-[var(--text-label-blue-france)]" ]
                            [ text (RuleValue.title size) ]
                        ]
                    , desc =
                        [ text "Parmi les véhicules de gabarit "
                        , span [ class "font-medium text-[var(--text-label-blue-france)]" ]
                            [ text (RuleValue.title size) ]
                        , text ", voici les meilleures alternatives pour votre usage."
                        , text " Sachant que vous "
                        , span [ class "font-medium text-[var(--text-label-blue-france)]" ]
                            [ if hasChargingStation.value then
                                text "avez"

                              else
                                text "n'avez pas"
                            , text " la possibilité d'avoir une borne de recharge."
                            ]
                        ]
                    , cheapest = targetCheapest
                    , greenest = targetGreenest
                    }
                , div []
                    [ viewAlternatives
                        { title = [ text "Les meilleures alternatives toutes catégories confondues" ]
                        , desc =
                            [ text "Parmi toutes les alternatives, voici les meilleures pour votre usage."
                            ]
                        , cheapest = cheapest
                        , greenest = greenest
                        }
                    , Accordion.single
                        { header = text "Voir toutes les alternatives"
                        , id = accordionComparisonTableId
                        , onClick = props.onToggleAccordion accordionComparisonTableId
                        , open =
                            Dict.get accordionComparisonTableId props.accordionsState
                                |> Maybe.withDefault False
                        , content =
                            Maybe.map2
                                Components.Simulateur.ComparisonTable.view
                                props.userCar
                                props.alternatives
                                |> Maybe.withDefault Components.LoadingCard.view
                        }
                    ]
                ]
    in
    div [ class "" ]
        [ div [ class "flex flex-col gap-8 mb-6 opacity-100" ]
            [ Components.Simulateur.Navigation.view
                { categories = props.categories
                , onNewStep = props.onNewStep
                , currentStep = Shared.SimulationStep.Result
                , containsErrors = False
                }
            , div [ class "flex flex-col gap-8 md:gap-20" ]
                [ section []
                    [ h2 [] [ text "Récapitulatif de votre situation" ]
                    , div [ class "fr-col-8" ]
                        [ case ( props.engineStatus, props.userCar ) of
                            ( _, Just user ) ->
                                Components.Simulateur.UserTotal.view
                                    { evaluations = props.evaluations
                                    , rules = props.rules
                                    , user = user
                                    }

                            _ ->
                                Components.LoadingCard.view
                        ]
                    , Accordion.single
                        { id = accordionCarbonId
                        , header = text "Qu'est-ce que l'empreinte carbone ?"
                        , onClick = props.onToggleAccordion accordionCarbonId
                        , open =
                            Dict.get accordionCarbonId props.accordionsState
                                |> Maybe.withDefault False
                        , content = carbonExplanation
                        }
                    ]
                , viewMaybe viewAlternativesSection props.targetInfos
                , viewSurveyCTA
                , viewAidesSection
                , viewRessourcesSection
                ]
            ]
        ]


carbonExplanation : Html msg
carbonExplanation =
    div []
        [ h3 []
            [ text "L'objectif des 2 tonnes" ]
        , p []
            [ text """
                            Pour essayer de maintenir l'augmentation
                            de la température moyenne de la planète en
                            dessous de 2 °C par rapport aux niveaux
                            préindustriels, il faudrait arriver à atteindre la """
            , a [ href "https://fr.wikipedia.org/wiki/Neutralit%C3%A9_carbone", target "_blank" ] [ text "neutralité carbone" ]
            , text "."
            ]
        , p []
            [ text "Pour cela, un objectif de 2 tonnes de CO2e par an et par personne a été fixé pour 2050 ("
            , a [ href "https://nosgestesclimat.fr/empreinte-climat", target "_blank" ]
                [ text "en savoir plus" ]
            , text ")."
            ]
        ]


viewAidesSection : Html msg
viewAidesSection =
    section []
        [ h2 [] [ text "Les aides financières" ]
        , p []
            [ text "Afin d'aider les particuliers à passer à des véhicules plus propres, il existe des aides financières mis en place par l'État et les collectivités locales."
            ]
        , div [ class "" ]
            [ CallOut.callout ""
                (span []
                    [ text "Au niveau national par exemple, avec le "
                    , a [ href "https://www.economie.gouv.fr/particuliers/bonus-ecologique", target "_blank" ]
                        [ text "bonus écologique" ]
                    , text ", vous pouvez bénéficier d'une aide allant jusqu'à "
                    , span [ class "text-[var(--text-default-info)]" ] [ text "4 000 €" ]
                    , text " pour l'achat d'un véhicule électrique."
                    ]
                )
            ]
        , p []
            [ text "Il existe également des aides locales auxquelles vous pouvez être éligible."
            ]
        , Button.new
            { onClick = Nothing
            , label = "Découvrir toutes les aides"
            }
            |> Button.linkButton "https://jagis.beta.gouv.fr"
            |> Button.rightIcon Icons.system.arrowRightFill
            |> Button.secondary
            |> Button.view
        ]


viewRessourcesSection : Html msg
viewRessourcesSection =
    let
        viewCard ( title, link, desc ) =
            Card.card
                (text title)
                Card.vertical
                |> Card.linkFull link
                |> Card.withDescription (Just (text desc))
                |> Card.withArrow True
                |> Card.view
    in
    section []
        [ h2 []
            [ text "Les ressources pour aller plus loin"
            ]
        , p [] [ text "Découvrez une sélection pour continuer votre engagement." ]
        , div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
            ([ ( "J'agis !"
               , "https://jagis.beta.gouv.fr"
               , "Faite vous accompagner pour réduire votre empreinte carbone à travers des actions concrètes."
               )
             , ( "Nos Gestes Climat"
               , "https://nosgestesclimat.fr"
               , "Calculez votre empreinte carbone individuelle et découvrez des gestes pour la réduire."
               )
             , ( "Impact CO2"
               , "https://impactCO2.fr"
               , "Comprendre les ordres de grandeur et les équivalences des émissions de CO2e."
               )
             ]
                |> List.map viewCard
                |> List.map (\card -> div [ class "fr-col-md-4" ] [ card ])
            )
        ]


viewSurveyCTA : Html msg
viewSurveyCTA =
    section [ class "fr-col-14 py-12 flex justify-center bg-[var(--background-alt-blue-france)] mx-[-3rem]" ]
        [ div [ class "bg-white py-6 rounded-xl border border-[var(--border-action-low-blue-france)] fr-col-8" ]
            [ div [ class "fr-container" ]
                [ h3 [ class "text-[var(--text-contrast-info)]" ]
                    [ text "👋 Donnez-nous votre avis !"
                    ]
                , p [ class "text-[var(--text-constrat-info)]" ]
                    [ text "Cet outil étant en construction, vous pouvez nous aider à l'améliorer en "
                    , span [ class "fr-text--bold text-[var(--text-label-blue-france)]" ] [ text "moins de 2 minutes" ]
                    , text " en répondant à notre questionnaire."
                    ]
                , Button.new
                    { onClick = Nothing
                    , label = "Répondre au questionnaire"
                    }
                    |> Button.linkButton "https://jagis.beta.gouv.fr"
                    |> Button.rightIcon Icons.system.arrowRightFill
                    |> Button.view
                ]
            ]
        ]
