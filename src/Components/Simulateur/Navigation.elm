module Components.Simulateur.Navigation exposing (view)

import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.Icons as Icons
import Core.UI as UI
import Helper
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import List.Extra
import Shared.SimulationStep as SimulationStep exposing (SimulationStep)


type alias Props msg =
    { categories : List UI.Category
    , onNewStep : SimulationStep -> msg
    , currentStep : SimulationStep
    , containsErrors : Bool
    }


view : Props msg -> Html msg
view props =
    let
        viewButton : Button.ButtonConfig msg -> Html msg
        viewButton config =
            Button.view
                (if props.containsErrors then
                    Button.disable config

                 else
                    config
                )
    in
    case props.currentStep of
        SimulationStep.NotStarted ->
            nothing

        SimulationStep.Category category ->
            let
                nextList =
                    Helper.dropUntilNext ((==) category) ("empty" :: props.categories)

                maybePrevCategory =
                    if List.head nextList == Just "empty" then
                        Nothing

                    else
                        List.head nextList

                maybeNextCategory =
                    nextList
                        |> List.drop 2
                        |> List.head
            in
            div [ class "flex justify-between mt-6" ]
                [ case maybePrevCategory of
                    Just prevCategory ->
                        Button.new
                            { onClick = Just (props.onNewStep (SimulationStep.Category prevCategory))
                            , label = "Retour"
                            }
                            |> Button.leftIcon Icons.system.arrowLeftSFill
                            |> Button.medium
                            |> Button.secondary
                            |> viewButton

                    _ ->
                        div [] []
                , case maybeNextCategory of
                    Just nextCategory ->
                        Button.new
                            { onClick = Just (props.onNewStep (SimulationStep.Category nextCategory))
                            , label = "Suivant"
                            }
                            |> Button.rightIcon Icons.system.arrowRightSFill
                            |> Button.medium
                            |> viewButton

                    _ ->
                        Button.new
                            { onClick = Just (props.onNewStep SimulationStep.Result)
                            , label = "Voir le résultat"
                            }
                            |> Button.rightIcon Icons.system.arrowRightSFill
                            |> Button.medium
                            |> viewButton
                ]

        SimulationStep.Result ->
            let
                lastCategory =
                    List.Extra.last props.categories
                        |> Maybe.withDefault ""
            in
            div [ class "flex justify-between mb-6" ]
                [ Button.new
                    { onClick = Just (props.onNewStep (SimulationStep.Category lastCategory))
                    , label = "Retourner aux questions"
                    }
                    |> Button.leftIcon Icons.system.arrowLeftSFill
                    |> Button.medium
                    |> Button.tertiary
                    |> viewButton
                ]
