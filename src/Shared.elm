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
import Core.Evaluation exposing (Evaluation)
import Core.Personas as Personas exposing (Personas)
import Core.Results.CarInfos
import Core.Results.TargetInfos
import Core.Rules
import Core.UI as UI
import Dict
import Effect exposing (Effect)
import Json.Decode
import Json.Decode.Pipeline as Decode
import Publicodes exposing (RawRules)
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
              }
            , Effect.none
            )

        Err e ->
            ( { emptyModel | decodeError = Just e }, Effect.none )



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
            ( { model
                | situation = newSituation
                , userCar = Nothing
                , alternatives = Nothing
                , targetInfos = Nothing
                , newInput = True
              }
            , Effect.none
            )

        SetSimulationStep newStep ->
            evaluate { model | simulationStep = newStep }

        ResetSimulation ->
            ( { model | inputErrors = Dict.empty, newInput = True }
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
            ( { model
                | situation = newSituation
                , userCar = Nothing
                , alternatives = Nothing
                , targetInfos = Nothing
                , newInput = True
              }
            , Effect.none
            )

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

        DecodeError err ->
            ( { model | decodeError = Just err }, Effect.none )

        NewUserCar car ->
            ( { model | userCar = Just car }, Effect.none )

        NewAlternatives alternatives ->
            ( { model | alternatives = Just alternatives }, Effect.none )

        NewTargetInfos target ->
            ( { model | targetInfos = Just target }, Effect.evaluateAlternatives )


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
            if model.simulationStep == SimulationStep.Result then
                ( { model
                    | engineStatus = EngineStatus.Evaluating
                    , newInput = False
                  }
                , Effect.batch
                    [ Effect.evaluateAll Core.Rules.userContext

                    -- , if model.newInput then
                    --     Effect.downloadSituation
                    --
                    --   else
                    --     Effect.none
                    , Effect.evaluateUserCar
                    , Effect.evaluateTargetCar
                    ]
                )

            else
                ( { model | engineStatus = EngineStatus.Evaluating }
                , currentQuestions
                    |> Effect.evaluateAll
                )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch
        [ Effect.onReactLinkClicked Shared.Msg.PushNewPath
        , Effect.onSituationUpdated (\_ -> Shared.Msg.Evaluate)
        , Effect.onEngineInitialized (\_ -> Shared.Msg.EngineInitialized)
        , Effect.onEngineError Shared.Msg.EngineError
        , Effect.onEvaluatedRules
            (\encodedEvaluations ->
                encodedEvaluations
                    |> decodeEvaluations
                    |> decodeErrorOr Shared.Msg.NewEvaluations
            )
        , Effect.onEvaluatedUserCar
            (\encodedCar ->
                encodedCar
                    |> Json.Decode.decodeValue Core.Results.CarInfos.decoder
                    |> decodeErrorOr Shared.Msg.NewUserCar
            )
        , Effect.onEvaluatedTargetCar
            (\encodedCar ->
                encodedCar
                    |> Json.Decode.decodeValue Core.Results.TargetInfos.decoder
                    |> decodeErrorOr Shared.Msg.NewTargetInfos
            )
        , Effect.onEvaluatedAlternatives
            (\encodedCars ->
                encodedCars
                    |> Json.Decode.decodeValue (Json.Decode.list Core.Results.CarInfos.decoder)
                    |> decodeErrorOr Shared.Msg.NewAlternatives
            )
        ]


decodeEvaluations : List ( RuleName, Json.Decode.Value ) -> Result Json.Decode.Error (List ( RuleName, Evaluation ))
decodeEvaluations encodedEvaluations =
    List.foldl
        (\( ruleName, encodedEvaluation ) result ->
            case result of
                Err _ ->
                    result

                Ok evaluations ->
                    encodedEvaluation
                        |> Json.Decode.decodeValue Core.Evaluation.decoder
                        |> Result.map
                            (\eval ->
                                ( ruleName, eval ) :: evaluations
                            )
        )
        (Ok [])
        encodedEvaluations


decodeErrorOr : (a -> Msg) -> Result Json.Decode.Error a -> Msg
decodeErrorOr okMsg result =
    case result of
        Ok a ->
            okMsg a

        Err e ->
            Shared.Msg.DecodeError e
