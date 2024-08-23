module Components.Simulateur.Result exposing (view)

import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.CallOut as CallOut
import BetaGouv.DSFR.Icons as Icons
import Components.DSFR.Card as Card
import Components.LoadingCard
import Components.Simulateur.ComparisonTable
import Components.Simulateur.Navigation
import Components.Simulateur.TotalCard as TotalCard
import Components.Simulateur.UserTotal
import Core.Result exposing (ComputedResult(..))
import Core.Rules as Rules
import Core.UI as UI
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing, viewMaybe)
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.RuleName exposing (RuleName)
import Shared.EngineStatus as EngineStatus exposing (EngineStatus(..))
import Shared.SimulationStep exposing (SimulationStep)


type alias Config msg =
    { categories : List UI.Category
    , onNewStep : SimulationStep -> msg
    , evaluations : Dict RuleName Evaluation
    , resultRules : List RuleName
    , rules : RawRules
    , engineStatus : EngineStatus
    }


view : Config msg -> Html msg
view props =
    let
        { userEmission, userCost } =
            Core.Result.getUserValues props.evaluations

        computedResults =
            Core.Result.getComputedResults
                { resultRules = props.resultRules
                , evaluations = props.evaluations
                , rules = props.rules
                }

        targetGabaritTitle =
            props.evaluations
                |> Core.Result.getStringValue Rules.targetGabarit
                |> Maybe.map
                    (\gabarit ->
                        Core.Result.getGabaritTitle gabarit props.rules
                    )
                |> Maybe.withDefault ""

        hasChargingStation =
            props.evaluations
                |> Core.Result.getBooleanValue Rules.targetChargingStation
                |> Maybe.withDefault True

        -- Sorts the computed results on the given attribute
        computedResultsSortedOn attr =
            computedResults
                |> List.sortWith
                    (Core.Result.compareWith
                        (\a b -> Basics.compare (attr a) (attr b))
                    )

        -- Filters the computed results on the given target (size, charging station)
        filterTarget =
            List.filter
                (\result ->
                    case result of
                        AlternativeCar infos ->
                            -- Only keep the results with the same target gabarit
                            -- TODO: use a +1/-1 comparison to be more flexible?
                            (infos.gabarit == targetGabaritTitle)
                                && -- Only keep the results with a charging station if the user has an electric car
                                   -- FIXME: "électrique" is hardcoded
                                   (hasChargingStation || infos.motorisation /= "Électrique")

                        CurrentUserCar _ ->
                            -- We ignre the user car
                            False
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

        viewAlternative : String -> Core.Result.ComputedResult -> Html msg
        viewAlternative title computedResult =
            case props.engineStatus of
                EngineStatus.Evaluating ->
                    Components.LoadingCard.view

                _ ->
                    div []
                        [ h4 [] [ text title ]
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
                                        { costToCompare = userCost
                                        , emissionToCompare = userEmission
                                        }
                                    |> TotalCard.view

                            CurrentUserCar _ ->
                                p [ class "rounded border fr-p-4v" ]
                                    [ text "Vous avez déjà la meilleure alternative !" ]
                        ]

        viewAlternatives args =
            case ( args.cheapest, args.greenest ) of
                ( Just cheapestAlternative, Just greenestAlternative ) ->
                    section [ class "fr-mt-12v" ]
                        [ h3 [] [ text args.title ]
                        , p [ class "fr-col-8" ] args.desc
                        , div [ class "grid grid-cols-2 gap-6" ]
                            [ viewAlternative "La plus économique" cheapestAlternative
                            , viewAlternative "La plus écologique" greenestAlternative
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
            , div [ class "flex flex-col gap-8" ]
                [ h1 []
                    [ text "Résultat" ]
                , section []
                    [ div [ class "fr-col-8" ]
                        [ case props.engineStatus of
                            EngineStatus.Done ->
                                Components.Simulateur.UserTotal.view
                                    { cost = userCost
                                    , emission = userEmission
                                    , evaluations = props.evaluations
                                    , rules = props.rules
                                    }

                            _ ->
                                Components.LoadingCard.view
                        ]

                    -- TODO: move it to a tooltip or accordion
                    , CallOut.callout "L'objectif des 2 tonnes"
                        (div []
                            [ p []
                                [ text """
                            Pour essayer de maintenir l'augmentation
                            de la température moyenne de la planète en
                            dessous de 2 °C par rapport aux niveaux
                            préindustriels, il faudrait arriver à atteindre la """
                                , a [ href "https://fr.wikipedia.org/wiki/Neutralit%C3%A9_carbone", target "_blank" ] [ text "neutralité carbone" ]
                                , text "."
                                ]
                            , br [] []
                            , p []
                                [ text "Pour cela, un objectif de 2 tonnes de CO2e par an et par personne a été fixé pour 2050 ("
                                , a [ href "https://nosgestesclimat.fr/empreinte-climat", target "_blank" ]
                                    [ text "en savoir plus" ]
                                , text ")."
                                ]
                            ]
                        )
                    ]
                , section []
                    [ h2 []
                        [ text "Comparaison avec les différentes alternatives"
                        ]
                    , p [ class "fr-col-8" ]
                        [ text "Pour le même usage de votre voiture, voici une comparaison de ce que cela pourrait donner avec d'autres types de véhicules."
                        ]
                    , viewAlternatives
                        { title = "Les meilleures alternatives pour votre usage"
                        , desc =
                            [ text "Parmi les véhicules de gabarit "
                            , span [ class "font-medium" ] [ text targetGabaritTitle ]
                            , text ", voici les meilleures alternatives pour votre usage."
                            , text " Sachant que vous "
                            , span [ class "font-medium" ]
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
                    , viewAlternatives
                        { title = "Les meilleures alternatives"
                        , desc =
                            [ text "Parmi toutes les alternatives, voici les meilleures pour votre usage."
                            ]
                        , cheapest = cheapest
                        , greenest = greenest
                        }
                    , case ( userEmission, userCost ) of
                        ( Just emission, Just cost ) ->
                            case props.engineStatus of
                                EngineStatus.Evaluating ->
                                    Components.LoadingCard.view

                                _ ->
                                    Components.Simulateur.ComparisonTable.view
                                        { rulesToCompare = computedResults
                                        , userEmission = emission
                                        , userCost = cost
                                        }

                        _ ->
                            Components.LoadingCard.view
                    ]
                , section [ class "fr-mt-12v fr-col-8" ]
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
                , section [ class "fr-mt-12v" ]
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
