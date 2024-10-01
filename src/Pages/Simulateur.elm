module Pages.Simulateur exposing (Model, Msg, page)

import BetaGouv.DSFR.Button
import BetaGouv.DSFR.Icons
import Components.Simulateur.Questions
import Components.Simulateur.Result
import Core.InputError exposing (InputError)
import Core.UI as UI
import Dict exposing (Dict)
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
import Shared.EngineStatus as EngineStatus
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
    Layouts.HeaderAndFooter { showReactRoot = False, contrastBg = True }



-- INIT


type alias Model =
    { accordionsState : Dict String Bool
    }


init : Shared.Model -> () -> ( Model, Effect Msg )
init shared () =
    let
        currentStep =
            getSimulationStep shared.simulationStep shared.orderedCategories
    in
    ( { accordionsState = Dict.empty }
    , Effect.setSimulationStep currentStep
    )


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
    | ResetSimulation
    | ToggleAccordion String


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
            ( model
            , Effect.batch
                [ Effect.setSimulationStep step
                , Effect.scrollToTop
                ]
            )

        ResetSimulation ->
            ( model, Effect.resetSimulation )

        ToggleAccordion id ->
            ( { model
                | accordionsState =
                    Dict.update id (Maybe.map not) model.accordionsState
              }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        inQuestions =
            case shared.simulationStep of
                SimulationStep.Category _ ->
                    True

                _ ->
                    False
    in
    { title = "Simulation - Quelle voiture choisir ?"
    , body =
        [ div [ class "fr-container" ]
            [ div [ class "fr-grid-row fr-grid-row--center" ]
                [ div
                    [ classList [ ( "fr-col-8", inQuestions ) ]
                    , class "fr-p-12v bg-[var(--background-default-grey)] rounded border-[1px] border-border-main"
                    ]
                    [ case shared.engineStatus of
                        EngineStatus.WithError msg ->
                            viewEngineError msg

                        _ ->
                            case shared.simulationStep of
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
                                        , engineStatus = shared.engineStatus
                                        , accordionsState = model.accordionsState
                                        , onToggleAccordion = ToggleAccordion
                                        }

                                SimulationStep.NotStarted ->
                                    -- Should not happen
                                    nothing
                    ]
                ]
            ]
        ]
    }


viewEngineError : String -> Html Msg
viewEngineError msg =
    div [ class "fr-text-red-600" ]
        [ EngineStatus.viewError msg
        , p [ class "fr-pt-4v text-[var(--text-default-error)]" ]
            [ text """
            Un problème est survenu. Nous vous invitons à réintialiser la
            simulation (vos réponses seront perdues).
            """
            ]
        , p [ class "text-[var(--text-default-error)]" ]
            [ text """
            Si le problème persiste, nous vous invitons à réassyer plus tard.
            Désolé pour la gêne occasionnée.
            """
            ]
        , BetaGouv.DSFR.Button.new
            { label = "Réinitialiser la simulation"
            , onClick = Just ResetSimulation
            }
            |> BetaGouv.DSFR.Button.primary
            |> BetaGouv.DSFR.Button.leftIcon
                BetaGouv.DSFR.Icons.system.refreshLine
            |> BetaGouv.DSFR.Button.view
        ]
