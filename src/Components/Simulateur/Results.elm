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
import Core.Results exposing (Results)
import Core.Results.CarInfos exposing (CarInfos)
import Core.Results.RuleValue as RuleValue
import Core.Rules as Rules
import Core.UI as UI
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes exposing (RawRules)
import Publicodes.RuleName exposing (RuleName)
import Shared.EngineStatus as EngineStatus exposing (EngineStatus(..))
import Shared.SimulationStep exposing (SimulationStep)


type alias Config msg =
    { categories : List UI.Category
    , onNewStep : SimulationStep -> msg
    , evaluations : Dict RuleName Evaluation
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
        targetInfos =
            getTargetInfos props.evaluations props.rules

        sortedAlternativesOn attr =
            props.results
                |> Maybe.map .alternatives
                |> Maybe.withDefault []
                |> List.sortWith
                    (\a b -> Basics.compare (attr a).value (attr b).value)

        -- Filters the alternatives results on the given target (size, charging station)
        filterInTarget : List CarInfos -> List CarInfos
        filterInTarget =
            case targetInfos of
                Nothing ->
                    identity

                Just { gabaritTitle, hasChargingStation } ->
                    List.filter
                        (\carInfo ->
                            -- Only keep the results with the same target gabarit
                            -- TODO: use a +1/-1 comparison to be more flexible?
                            let
                                sameSize =
                                    Maybe.map (\sizeTitle -> sizeTitle == gabaritTitle) carInfo.size.title
                                        |> Maybe.withDefault False

                                elecAndHasChargingStation =
                                    hasChargingStation || carInfo.motorisation.value /= "électrique"
                            in
                            -- Only keep the results with a charging station if the user has an electric car
                            sameSize && elecAndHasChargingStation
                        )

        alternativesSortedOnCost =
            sortedAlternativesOn .cost

        -- (\{ cost } -> cost.value)
        alternativesSortedOnEmission =
            sortedAlternativesOn .emissions

        --(\{ emissions } -> emissions.value)
        cheapest =
            List.head alternativesSortedOnCost

        greenest =
            List.head alternativesSortedOnEmission

        targetCheapest =
            alternativesSortedOnCost
                |> filterInTarget
                |> List.head

        targetGreenest =
            alternativesSortedOnEmission
                |> filterInTarget
                |> List.head

        viewAlternative : Icons.IconName -> String -> CarInfos -> Html msg
        viewAlternative icon title infos =
            case ( props.engineStatus, props.results ) of
                ( EngineStatus.Done, Just { user } ) ->
                    div []
                        [ h4 [ class "flex gap-2 items-center" ]
                            [ Icons.iconMD icon
                            , text title
                            ]
                        , TotalCard.new
                            { title = Maybe.withDefault "" infos.title
                            , cost = infos.cost.value
                            , emission = infos.emissions.value
                            }
                            |> -- NOTE: maybe not relevant as infomration is already in the title
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
                            |> TotalCard.view

                        -- TODO: case where the user car is the best option
                        -- CurrentUserCar _ ->
                        --     div [ class "flex gap-2 items-center font-medium rounded-md fr-my-4v fr-p-4v outline outline-1 outline-[var(--border-plain-success)] text-[var(--text-default-success)]" ]
                        --         [ Icons.iconMD Icons.system.successLine
                        --         , text "Vous avez déjà la meilleure alternative !"
                        --         ]
                        ]

                _ ->
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
                            ( EngineStatus.Done, Just { user } ) ->
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
                    [ case targetInfos of
                        Just { gabaritTitle, hasChargingStation } ->
                            viewAlternatives
                                { title =
                                    [ text "Les meilleures alternatives pour le gabarit "
                                    , span [ class "fr-px-3v bg-[var(--background-contrast-grey)]" ]
                                        [ text gabaritTitle ]
                                    ]
                                , desc =
                                    [ text "Parmi les véhicules de gabarit "
                                    , span [ class "font-medium fr-px-1v bg-[var(--background-contrast-grey)]" ]
                                        [ text gabaritTitle ]
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

                        _ ->
                            nothing
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
                                props.results
                                    |> Maybe.map Components.Simulateur.ComparisonTable.view
                                    |> Maybe.withDefault Components.LoadingCard.view
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


getTargetInfos :
    Dict RuleName Evaluation
    -> RawRules
    -> Maybe { gabaritTitle : String, hasChargingStation : Bool }
getTargetInfos evaluations rules =
    let
        gabaritTitle =
            evaluations
                |> Core.Results.getStringValue Rules.targetGabarit
                |> Maybe.map
                    (\gabarit ->
                        Core.Results.getGabaritTitle gabarit rules
                    )

        hasChargingStation =
            Core.Results.getBooleanValue Rules.targetChargingStation evaluations
    in
    Maybe.map2
        (\g c -> { gabaritTitle = g, hasChargingStation = c })
        gabaritTitle
        hasChargingStation
