module Components.CategoryNavigation exposing (view)

import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.Icons as Icons
import Core.UI as UI
import Helper
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import List.Extra
import Shared.Model exposing (SimulationStep(..))


type alias Props msg =
    { categories : List UI.Category
    , onNewStep : Shared.Model.SimulationStep -> msg
    , currentStep : Shared.Model.SimulationStep
    }


view : Props msg -> Html msg
view props =
    case props.currentStep of
        NotStarted ->
            nothing

        Category category ->
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
                            { onClick = Just (props.onNewStep (Category prevCategory))
                            , label = "Retour"
                            }
                            |> Button.leftIcon Icons.system.arrowLeftSFill
                            |> Button.medium
                            |> Button.secondary
                            |> Button.view

                    _ ->
                        div [] []
                , case maybeNextCategory of
                    Just nextCategory ->
                        Button.new
                            { onClick = Just (props.onNewStep (Category nextCategory))
                            , label = "Suivant"
                            }
                            |> Button.rightIcon Icons.system.arrowRightSFill
                            |> Button.medium
                            |> Button.view

                    _ ->
                        Button.new
                            { onClick = Just (props.onNewStep Result)
                            , label = "Voir le résultat"
                            }
                            |> Button.rightIcon Icons.system.arrowRightSFill
                            |> Button.medium
                            |> Button.view
                ]

        Result ->
            let
                lastCategory =
                    List.Extra.last props.categories
                        |> Maybe.withDefault ""
            in
            div [ class "flex justify-between mb-6" ]
                [ Button.new
                    { onClick = Just (props.onNewStep (Category lastCategory))
                    , label = "Retourner aux questions"
                    }
                    |> Button.leftIcon Icons.system.arrowLeftSFill
                    |> Button.medium
                    |> Button.tertiary
                    |> Button.view
                ]
