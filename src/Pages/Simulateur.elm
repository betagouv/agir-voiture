module Pages.Simulateur exposing (Model, Msg, page)

import Components.Simulateur.Questions
import Components.Simulateur.Result
import Core.InputError exposing (InputError)
import Core.UI as UI
import Dict
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Layouts
import Page exposing (Page)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)
import Route exposing (Route)
import Shared
import Shared.SimulationStep as SimulationStep exposing (SimulationStep)
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
    Layouts.Header { showReactRoot = False, contrastBg = True }



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
        SimulationStep.NotStarted ->
            List.head orderedCategories
                |> Maybe.map SimulationStep.Category
                |> Maybe.withDefault SimulationStep.NotStarted

        _ ->
            step



-- UPDATE


type Msg
    = NoOp
    | NewAnswer ( RuleName, NodeValue, Maybe InputError )
    | NewStep SimulationStep


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        NewAnswer ( name, value, Nothing ) ->
            ( model
            , Effect.batch
                [ Effect.removeInputError name
                , Effect.updateSituation ( name, value )
                ]
            )

        NewAnswer ( name, value, Just error ) ->
            ( model
            , Effect.newInputError
                { name = name
                , value = NodeValue.toString value
                , msg = Core.InputError.toMessage error
                }
            )

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
                SimulationStep.Category _ ->
                    True

                _ ->
                    False
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
                div [ class "fr-container" ]
                    [ div [ class "fr-grid-row fr-grid-row--center" ]
                        [ div
                            [ classList [ ( "fr-col-8", inQuestions ) ]
                            , class "fr-p-12v bg-[var(--background-default-grey)] rounded border-[1px] border-border-main"
                            ]
                            [ case shared.simulationStep of
                                SimulationStep.Category category ->
                                    case Dict.get category shared.ui.questions of
                                        Just questions ->
                                            Components.Simulateur.Questions.view
                                                { category = category
                                                , rules = shared.rules
                                                , questions = questions
                                                , categories = shared.orderedCategories
                                                , situation = shared.situation
                                                , evaluations = shared.evaluations
                                                , onInput =
                                                    \name value error ->
                                                        NewAnswer ( name, value, error )
                                                , onNewStep = \step -> NewStep step
                                                , inputErrors = shared.inputErrors
                                                , currentStep = shared.simulationStep
                                                }

                                        Nothing ->
                                            nothing

                                SimulationStep.Result ->
                                    Components.Simulateur.Result.view
                                        { categories = shared.orderedCategories
                                        , onNewStep = \step -> NewStep step
                                        , evaluations = shared.evaluations
                                        , resultRules = shared.resultRules
                                        , rules = shared.rules
                                        }

                                SimulationStep.NotStarted ->
                                    -- Should not happen
                                    nothing
                            ]
                        ]
                    ]
            ]
        ]
    }
