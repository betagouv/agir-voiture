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

import Core.Personas as Personas exposing (Personas)
import Core.Rules as Rules
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
import Shared.Model exposing (SimulationStep(..))
import Shared.Msg exposing (Msg(..))



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
    , simulationStep : Shared.Model.SimulationStep
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.succeed Flags
        |> Decode.required "rules" Publicodes.decodeRawRules
        |> Decode.required "ui" UI.decode
        |> Decode.required "personas" Personas.personasDecoder
        |> Decode.required "situation" Situation.decoder
        |> Decode.required "simulationStep" Shared.Model.simulationStepDecoder



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
                , resultRules = Rules.getResultRules flags.rules
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
            evaluate
                { model | situation = newSituation }

        SetSimulationStep newStep ->
            evaluate { model | simulationStep = newStep }

        ResetSimulation ->
            ( model
            , Effect.batch
                [ Effect.setSituation Dict.empty
                , Effect.setSimulationStep Shared.Model.NotStarted
                , Effect.pushRoutePath Route.Path.Home_
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
            ( { model | evaluations = newEvaluations }, Effect.none )

        UpdateSituation ( name, value ) ->
            let
                newSituation =
                    Dict.insert name value model.situation
            in
            ( { model | situation = newSituation }, Effect.none )

        Evaluate ->
            evaluate model


{-| Evaluates rules to update according to the current simulation step.
-}
evaluate : Model -> ( Model, Effect Msg )
evaluate model =
    -- TODO: do we need to check if the shared.engineInitialized is true?
    let
        currentQuestions =
            case model.simulationStep of
                Category category ->
                    Dict.get category model.ui.questions
                        |> Maybe.withDefault []
                        |> List.concat

                _ ->
                    []
    in
    ( model
    , if model.simulationStep == Result then
        [ Rules.userCost, Rules.userEmission ]
            ++ model.resultRules
            |> Effect.evaluateAll

      else
        currentQuestions
            -- ++ TODO: not needed a priori model.orderedCategories
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
