module Components.Simulateur.Stepper exposing (view)

import Core.UI as UI
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes
import Publicodes.Helpers
import Shared.SimulationStep as SimulationStep exposing (SimulationStep)


type alias Props =
    { rules : Publicodes.RawRules
    , categories : List UI.Category
    , currentStep : SimulationStep
    }


view : Props -> Html msg
view props =
    let
        currentTab =
            case props.currentStep of
                SimulationStep.Category category ->
                    category

                _ ->
                    ""

        { nextIndex, maybeCurrentTitle, maybeNextTitle } =
            getTitles currentTab props

        currentNumStep =
            String.fromInt nextIndex

        totalNumStep =
            String.fromInt (List.length props.categories)
    in
    -- TODO: extract the stepper into Components.DSFR.Stepper
    div [ class "fr-stepper" ]
        [ h2 [ class "fr-stepper__title" ]
            [ case props.currentStep of
                SimulationStep.NotStarted ->
                    text "Démarrer"

                SimulationStep.Category _ ->
                    text (Maybe.withDefault "" maybeCurrentTitle)

                SimulationStep.Result ->
                    text "Résultat"
            ]
        , span [ class "fr-stepper__state" ]
            [ text (String.join " " [ "Étape", currentNumStep, "sur", totalNumStep ])
            ]
        , div
            [ class "fr-stepper__steps"
            , attribute "data-fr-current-step" currentNumStep
            , attribute "data-fr-steps" totalNumStep
            ]
            []
        , case maybeNextTitle of
            Just title ->
                p [ class "fr-stepper__details" ]
                    [ span [ class "fr-text--bold" ] [ text "Étape suivante : " ]
                    , text title
                    ]

            _ ->
                nothing
        ]


{-| Traverses the (ordered) categories to find the information about
the current and next category titles.
-}
getTitles :
    String
    -> Props
    ->
        { nextIndex : Int
        , maybeCurrentTitle : Maybe String
        , maybeNextTitle : Maybe String
        }
getTitles currentTab props =
    props.categories
        |> List.foldl
            (\category infos ->
                let
                    categoryTitle =
                        Publicodes.Helpers.getTitle category props.rules
                in
                if category == currentTab then
                    { infos
                        | nextIndex = infos.nextIndex + 1
                        , maybeCurrentTitle = Just categoryTitle
                    }

                else
                    case ( infos.maybeCurrentTitle, infos.maybeNextTitle ) of
                        ( Just _, Nothing ) ->
                            { infos | maybeNextTitle = Just categoryTitle }

                        ( Nothing, Nothing ) ->
                            { infos | nextIndex = infos.nextIndex + 1 }

                        _ ->
                            infos
            )
            { nextIndex = 0
            , maybeCurrentTitle = Nothing
            , maybeNextTitle = Nothing
            }
