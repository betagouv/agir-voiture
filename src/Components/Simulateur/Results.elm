module Components.Simulateur.Results exposing (view)

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
import Core.Results exposing (ComputedResult(..), Results)
import Core.Rules as Rules
import Core.UI as UI
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes exposing (RawRules)
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName exposing (RuleName)
import Shared.EngineStatus as EngineStatus exposing (EngineStatus(..))
import Shared.SimulationStep exposing (SimulationStep)


type alias Config msg =
    { categories : List UI.Category
    , onNewStep : SimulationStep -> msg
    , evaluations : Dict RuleName Evaluation
    , resultRules : List RuleName
    , rules : RawRules
    , results : Maybe Results
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
        maybeUserCarInfos =
            Maybe.map .user props.results

        computedResults =
            Core.Results.getComputedResults
                { resultRules = props.resultRules
                , evaluations = props.evaluations
                , rules = props.rules
                }

        targetGabaritTitle =
            props.evaluations
                |> Core.Results.getStringValue Rules.targetGabarit
                |> Maybe.map
                    (\gabarit ->
                        Core.Results.getGabaritTitle gabarit props.rules
                    )
                |> Maybe.withDefault ""

        hasChargingStation =
            props.evaluations
                |> Core.Results.getBooleanValue Rules.targetChargingStation
                |> Maybe.withDefault True

        -- Sorts the computed results on the given attribute
        computedResultsSortedOn attr =
            computedResults
                |> List.sortWith
                    (Core.Results.compareWith
                        (\a b -> Basics.compare (attr a) (attr b))
                    )

        -- Filters the computed results on the given target (size, charging station)
        filterTarget =
            List.filter
                (\result ->
                    let
                        ( gabarit, motorisation ) =
                            case result of
                                AlternativeCar infos ->
                                    ( infos.gabarit, infos.motorisation )

                                CurrentUserCar infos ->
                                    ( infos.gabarit, infos.motorisation )
                    in
                    -- Only keep the results with the same target gabarit
                    -- TODO: use a +1/-1 comparison to be more flexible?
                    (gabarit == targetGabaritTitle)
                        && -- Only keep the results with a charging station if the user has an electric car
                           -- FIXME: "électrique" is hardcoded
                           (hasChargingStation || motorisation /= "Électrique")
                )

        computedResultsSortedOnCost =
            computedResultsSortedOn .cost

        computedResultsSortedOnEmission =
            computedResultsSortedOn .emission

        cheapest =
            List.head computedResultsSortedOnCost

        greenest =
            List.head computedResultsSortedOnEmission

        targetCheapest =
            computedResultsSortedOnCost
                |> filterTarget
                |> List.head

        targetGreenest =
            computedResultsSortedOnEmission
                |> filterTarget
                |> List.head

        viewAlternative : Icons.IconName -> String -> Core.Results.ComputedResult -> Html msg
        viewAlternative icon title computedResult =
            case ( props.engineStatus, maybeUserCarInfos ) of
                ( EngineStatus.Done, Just userCarInfos ) ->
                    div []
                        [ h4 [ class "flex gap-2 items-center" ]
                            [ Icons.iconMD icon
                            , text title
                            ]
                        , case computedResult of
                            AlternativeCar infos ->
                                TotalCard.new
                                    { title = infos.title
                                    , cost = infos.cost
                                    , emission = infos.emission
                                    }
                                    |> TotalCard.withContext
                                        ([ infos.gabarit
                                         , infos.motorisation
                                         , Maybe.withDefault "" infos.carburant
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
                                        { costToCompare =
                                            NodeValue.toFloat userCarInfos.cost.value
                                        , emissionToCompare =
                                            NodeValue.toFloat userCarInfos.emissions.value
                                        }
                                    |> TotalCard.view

                            CurrentUserCar _ ->
                                div [ class "flex gap-2 items-center font-medium rounded-md fr-my-4v fr-p-4v outline outline-1 outline-[var(--border-plain-success)] text-[var(--text-default-success)]" ]
                                    [ Icons.iconMD Icons.system.successLine
                                    , text "Vous avez déjà la meilleure alternative !"
                                    ]
                        ]

                _ ->
                    -- TODO: we may want to show error messages for invalid state
                    Components.LoadingCard.view

        viewAlternatives args =
            case ( args.cheapest, args.greenest ) of
                ( Just cheapestAlternative, Just greenestAlternative ) ->
                    section []
                        [ h2 [] args.title
                        , p [ class "fr-col-8" ] args.desc
                        , div [ class "grid grid-cols-2 gap-6" ]
                            [ viewAlternative Icons.finance.moneyEuroCircleLine "La plus économique" cheapestAlternative
                            , viewAlternative Icons.others.leafLine "La plus écologique" greenestAlternative
                            ]
                        ]

                _ ->
                    nothing

        viewCard ( title, link, desc ) =
            Card.card
                (text title)
                Card.vertical
                |> Card.linkFull link
                |> Card.withDescription
                    (Just
                        (text desc)
                    )
                |> Card.withArrow True
                |> Card.view
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
                    [ h2 []
                        [ text "Récapitulatif de votre situation"
                        ]
                    , div [ class "fr-col-8" ]
                        [ case ( props.engineStatus, props.results ) of
                            ( EngineStatus.Done, Just results ) ->
                                Components.Simulateur.UserTotal.view
                                    { evaluations = props.evaluations
                                    , rules = props.rules
                                    , user = results.user
                                    }

                            ( EngineStatus.Done, Nothing ) ->
                                -- TODO: should not happen
                                Components.LoadingCard.view

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
                        , content =
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
                        }
                    ]
                , section [ class "flex flex-col md:gap-20" ]
                    [ viewAlternatives
                        { title =
                            [ text "Les meilleures alternatives pour le gabarit "
                            , span [ class "fr-px-3v bg-[var(--background-contrast-grey)]" ]
                                [ text targetGabaritTitle ]
                            ]
                        , desc =
                            [ text "Parmi les véhicules de gabarit "
                            , span [ class "font-medium fr-px-1v bg-[var(--background-contrast-grey)]" ] [ text targetGabaritTitle ]
                            , text ", voici les meilleures alternatives pour votre usage."
                            , text " Sachant que vous "
                            , span [ class "font-medium fr-px-1v bg-[var(--background-contrast-grey)]" ]
                                [ if hasChargingStation then
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
                                case maybeUserCarInfos of
                                    Just user ->
                                        case
                                            ( NodeValue.toFloat user.cost.value
                                            , NodeValue.toFloat user.emissions.value
                                            )
                                        of
                                            ( Just userCost, Just userEmission ) ->
                                                Components.Simulateur.ComparisonTable.view
                                                    { rulesToCompare = computedResults
                                                    , userCost = userCost
                                                    , userEmission = userEmission
                                                    }

                                            _ ->
                                                -- FIXME: show error message
                                                Components.LoadingCard.view

                                    _ ->
                                        Components.LoadingCard.view
                            }
                        ]
                    ]
                , section [ class "fr-col-8" ]
                    [ h2 [] [ text "Les aides financières" ]
                    , p []
                        [ text """
                            Afin d'aider les particuliers à passer à des véhicules plus propres, il existe des aides financières
                            mis en place par l'État et les collectivités locales."""
                        ]
                    , CallOut.callout ""
                        (span []
                            [ text "Au niveau national par exemple, avec le "
                            , a [ href "https://www.economie.gouv.fr/particuliers/bonus-ecologique", target "_blank" ]
                                [ text "bonus écologique" ]
                            , text ", vous pouvez bénéficier d'une aide allant jusqu'à "
                            , span [ class "text-[var(--text-default-info)]" ] [ text "7 000 €" ]
                            , text " pour l'achat d'un véhicule électrique. Et avec la "
                            , a [ href "https://www.service-public.fr/particuliers/vosdroits/F36848", target "_blank" ]
                                [ text "prime à la conversion" ]
                            , text ", vous pouvez bénéficier d'une aide allant jusqu'à "
                            , span [ class "text-[var(--text-default-info)]" ] [ text "3 000 €" ]
                            , text "."
                            ]
                        )
                    , p []
                        [ text "Il existe également des aides locales auxquelles vous pouvez être éligible."
                        ]
                    , Button.new
                        { onClick = Nothing
                        , label = "Découvrir toutes les aides"
                        }
                        |> Button.linkButton "https://agir.beta.gouv.fr"
                        |> Button.rightIcon Icons.system.arrowRightFill
                        |> Button.view
                    ]
                , section []
                    [ h2 []
                        [ text "Les ressources pour aller plus loin"
                        ]
                    , p [] [ text "Découvrez une sélection pour continuer votre engagement." ]
                    , div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
                        ([ ( "Agir !"
                           , "https://agir.beta.gouv.fr"
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
                ]
            ]
        ]
