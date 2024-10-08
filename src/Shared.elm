module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions

-}

import Browser.Navigation
import Core.Personas as Personas exposing (Personas)
import Core.Result
import Core.Rules
import Core.UI as UI
import Dict
import Effect exposing (Effect)
import Json.Decode
import Json.Decode.Pipeline as Decode
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation as Situation exposing (Situation)
import Route exposing (Route)
import Route.Path
import Shared.EngineStatus as EngineStatus
import Shared.Model
import Shared.Msg exposing (Msg(..))
import Shared.SimulationStep as SimulationStep exposing (SimulationStep)



-- FLAGS


{-| Contains the data passed to the page when it is created.

Most of them are stored persistently in the local storage (see the `interop.ts`
file to have more information about the data stored).

-}
type alias Flags =
    { rules : RawRules
    , ui : UI.Data
    , personas : Personas
    , situation : Situation
    , simulationStep : SimulationStep
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.succeed Flags
        |> Decode.required "rules" Publicodes.decodeRawRules
        |> Decode.required "ui" UI.decode
        |> Decode.required "personas" Personas.personasDecoder
        |> Decode.required "situation" Situation.decoder
        |> Decode.required "simulationStep" SimulationStep.decoder



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult _ =
    let
        emptyModel =
            Shared.Model.empty
    in
    case flagsResult of
        Ok flags ->
            ( { emptyModel
                | situation = flags.situation
                , rules = flags.rules
                , simulationStep = flags.simulationStep
                , ui = flags.ui
                , personas = flags.personas
                , orderedCategories = UI.getOrderedCategories flags.ui.categories
                , resultRules = Core.Result.getResultRules flags.rules
              }
            , Effect.none
            )

        Err _ ->
            -- TODO: handle error
            ( emptyModel, Effect.none )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        PushNewPath stringPath ->
            let
                path =
                    Route.Path.fromString stringPath
                        |> Maybe.withDefault Route.Path.NotFound_
            in
            ( model
            , Effect.pushRoutePath path
            )

        SetSituation newSituation ->
            ( { model | situation = newSituation }, Effect.none )

        SetSimulationStep newStep ->
            evaluate { model | simulationStep = newStep }

        ResetSimulation ->
            ( { model | inputErrors = Dict.empty }
            , Effect.batch
                [ Effect.setSituation Dict.empty
                , Effect.setSimulationStep SimulationStep.NotStarted
                , Effect.restartEngine
                , Effect.pushRoutePath Route.Path.Home_
                , Effect.sendCmd Browser.Navigation.reload
                ]
            )

        NewEvaluations evaluations ->
            let
                newEvaluations =
                    evaluations
                        |> List.foldl
                            (\( ruleName, evaluation ) ->
                                Dict.insert ruleName evaluation
                            )
                            model.evaluations
            in
            ( { model
                | engineStatus = EngineStatus.Done
                , evaluations = newEvaluations
              }
            , Effect.none
            )

        UpdateSituation ( name, value ) ->
            let
                newSituation =
                    Dict.insert name value model.situation
            in
            ( { model | situation = newSituation }, Effect.none )

        Evaluate ->
            evaluate model

        NewInputError error ->
            ( { model
                | inputErrors =
                    Dict.insert error.name
                        { value = error.value, msg = error.msg }
                        model.inputErrors
              }
            , Effect.none
            )

        RemoveInputError name ->
            ( { model
                | inputErrors =
                    Dict.remove name model.inputErrors
              }
            , Effect.none
            )

        EngineInitialized ->
            case model.engineStatus of
                EngineStatus.NotInitialized ->
                    ( { model | engineStatus = EngineStatus.Done }
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        EngineError errorMsg ->
            ( { model | engineStatus = EngineStatus.WithError errorMsg }
            , Effect.none
            )


{-| Evaluates rules to update according to the current simulation step.
-}
evaluate : Model -> ( Model, Effect Msg )
evaluate model =
    case model.engineStatus of
        EngineStatus.WithError _ ->
            -- We don't want to evaluate rules if the engine is in error
            ( model, Effect.none )

        _ ->
            -- TODO: do we need to check if the shared.engineInitialized is true?
            let
                currentQuestions =
                    case model.simulationStep of
                        SimulationStep.Category category ->
                            Dict.get category model.ui.questions
                                |> Maybe.withDefault []

                        _ ->
                            []
            in
            ( { model | engineStatus = EngineStatus.Evaluating }
            , if model.simulationStep == SimulationStep.Result then
                [ Core.Rules.userCost
                , Core.Rules.userEmission
                , Core.Rules.targetGabarit
                , Core.Rules.targetChargingStation
                ]
                    ++ Core.Rules.userContext
                    ++ model.resultRules
                    |> Effect.evaluateAll

              else
                currentQuestions
                    |> Effect.evaluateAll
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch
        [ Effect.onReactLinkClicked Shared.Msg.PushNewPath
        , Effect.onEvaluatedRules
            (\encodedEvaluations ->
                Shared.Msg.NewEvaluations (decodeEvaluations encodedEvaluations)
            )
        , Effect.onSituationUpdated (\_ -> Evaluate)
        , Effect.onEngineInitialized (\_ -> EngineInitialized)
        , Effect.onEngineError EngineError
        ]


decodeEvaluations : List ( RuleName, Json.Decode.Value ) -> List ( RuleName, Evaluation )
decodeEvaluations evaluations =
    List.filterMap
        (\( ruleName, encodedEvaluation ) ->
            Json.Decode.decodeValue Publicodes.evaluationDecoder encodedEvaluation
                |> Result.toMaybe
                |> Maybe.map (\evaluation -> ( ruleName, evaluation ))
        )
        evaluations
