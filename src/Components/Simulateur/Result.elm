module Components.Simulateur.Result exposing (view)

import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.CallOut as CallOut
import BetaGouv.DSFR.Icons as Icons
import Components.DSFR.Card as Card
import Components.Simulateur.ComparisonTable
import Components.Simulateur.Navigation
import Components.Simulateur.UserTotal
import Core.Rules
import Core.UI as UI
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import List.Extra
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.RuleName exposing (RuleName)
import Shared.Model exposing (SimulationStep(..))


type alias Config msg =
    { categories : List UI.Category
    , onNewStep : Shared.Model.SimulationStep -> msg
    , evaluations : Dict RuleName Evaluation
    , resultRules : List RuleName
    , rules : RawRules
    }


view : Config msg -> Html msg
view props =
    let
        { userEmission, userCost } =
            Core.Rules.getUserValues props.evaluations

        rulesToCompare =
            props.resultRules
                |> List.filterMap
                    (\name ->
                        case Publicodes.RuleName.split name of
                            namespace :: rest ->
                                if List.member namespace Core.Rules.resultNamespaces then
                                    Just rest

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )
                |> List.Extra.unique

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
                , currentStep = Shared.Model.Result
                }
            , div [ class "flex flex-col gap-8" ]
                [ h1 []
                    [ text "Résultat" ]
                , section []
                    [ Components.Simulateur.UserTotal.viewParagraph
                        { cost = userCost, emission = userEmission }
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
                    , p []
                        [ text "Pour le même usage de votre voiture, voici une comparaison de ce que cela pourrait donner avec d'autres types de véhicules."
                        ]
                    , case ( userEmission, userCost ) of
                        ( Just emission, Just cost ) ->
                            Components.Simulateur.ComparisonTable.view
                                { rawRules = props.rules
                                , evaluations = props.evaluations
                                , rulesToCompare = rulesToCompare
                                , userEmission = emission
                                , userCost = cost
                                }

                        _ ->
                            text "No user emission or cost"
                    ]
                , section []
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
                , section [ class "mt-8" ]
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
