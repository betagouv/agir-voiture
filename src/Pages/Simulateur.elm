module Pages.Simulateur exposing (Model, Msg, page)

import Components.Simulateur.Questions
import Components.Simulateur.Result
import Components.Simulateur.Stepper
import Core.UI as UI
import Dict
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing, viewIfLazy)
import Layouts
import Page exposing (Page)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)
import Route exposing (Route)
import Shared
import Shared.Model exposing (SimulationStep(..))
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared _ =
    Page.new
        { init = init shared
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout _ =
    Layouts.Header { showReactRoot = False }



-- INIT


type alias Model =
    ()


init : Shared.Model -> () -> ( Model, Effect Msg )
init shared () =
    let
        currentStep =
            getSimulationStep shared.simulationStep shared.orderedCategories
    in
    ( (), Effect.setSimulationStep currentStep )


{-| Returns the simulation step to display.

If it's \`NotStarted, it will return the first category of the list.

-}
getSimulationStep : SimulationStep -> List UI.Category -> SimulationStep
getSimulationStep step orderedCategories =
    case step of
        NotStarted ->
            List.head orderedCategories
                |> Maybe.map Category
                |> Maybe.withDefault NotStarted

        _ ->
            step



-- UPDATE


type Msg
    = NoOp
    | NewAnswer ( RuleName, NodeValue )
    | NewStep SimulationStep


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        NewAnswer (( name, value ) as input) ->
            let
                manageError =
                    case value of
                        NodeValue.Str "" ->
                            Effect.newInputError ( name, "Ce champ est obligatoire" )

                        _ ->
                            Effect.removeInputError name
            in
            ( model, Effect.batch [ manageError, Effect.updateSituation input ] )

        NewStep step ->
            ( model, Effect.setSimulationStep step )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared _ =
    let
        inQuestions =
            case shared.simulationStep of
                Category _ ->
                    True

                _ ->
                    False

        newAnswer : RuleName -> String -> Msg
        newAnswer ruleName stringValue =
            case String.toFloat stringValue of
                Just value ->
                    NewAnswer ( ruleName, NodeValue.Number value )

                Nothing ->
                    NewAnswer ( ruleName, NodeValue.Str stringValue )
    in
    { title = "Simulateur - Quelle voiture choisir ?"
    , body =
        [ div []
            [ if Dict.isEmpty shared.evaluations then
                div [ class "flex flex-col w-full h-full items-center" ]
                    [ div [ class "text-primary my-4" ]
                        [ -- NOTE: the loading is to fast to show a message
                          nothing
                        ]
                    ]

              else
                div [ class "fr-container md:my-8" ]
                    [ viewIfLazy inQuestions
                        (\() ->
                            Components.Simulateur.Stepper.view
                                { rules = shared.rules
                                , categories = shared.orderedCategories
                                , currentStep = shared.simulationStep
                                }
                        )
                    , case shared.simulationStep of
                        Category category ->
                            case Dict.get category shared.ui.questions of
                                Just questions ->
                                    Components.Simulateur.Questions.view
                                        { category = category
                                        , rules = shared.rules
                                        , questions = questions
                                        , categories = shared.orderedCategories
                                        , situation = shared.situation
                                        , evaluations = shared.evaluations
                                        , onInput = newAnswer
                                        , onNewStep = \step -> NewStep step
                                        , inputErrors = shared.inputErrors
                                        }

                                Nothing ->
                                    nothing

                        Result ->
                            Components.Simulateur.Result.view
                                { categories = shared.orderedCategories
                                , onNewStep = \step -> NewStep step
                                , evaluations = shared.evaluations
                                , resultRules = shared.resultRules
                                , rules = shared.rules
                                }

                        NotStarted ->
                            -- Should not happen
                            nothing
                    ]
            ]
        ]
    }
