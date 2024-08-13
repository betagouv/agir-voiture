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

import Dict
import Effect exposing (Effect)
import Json.Decode
import Json.Decode.Pipeline as Decode
import Publicodes exposing (RawRules)
import Publicodes.Situation as Situation exposing (Situation)
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg exposing (Msg(..))



-- FLAGS


{-| Contains the data passed to the page when it is created.

Most of them are stored persistently in the local storage (see the `interop.ts`
file to have more information about the data stored).

-}
type alias Flags =
    { rules : RawRules
    , situation : Situation
    , simulationStep : Shared.Model.SimulationStep
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.succeed Flags
        |> Decode.required "rules" Publicodes.rawRulesDecoder
        |> Decode.required "situation" Situation.decoder
        |> Decode.required "simulationStep" Shared.Model.simulationStepDecoder



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult _ =
    case flagsResult of
        Ok flags ->
            ( { situation = flags.situation
              , rules = flags.rules
              , simulationStep = flags.simulationStep
              }
            , Effect.none
            )

        Err _ ->
            -- TODO: handle error
            ( Shared.Model.empty, Effect.none )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
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
            ( { model | situation = newSituation }
            , Effect.none
            )

        SetSimulationStep newStep ->
            ( { model | simulationStep = newStep }
            , Effect.none
            )

        ResetSimulation ->
            ( model
            , Effect.batch
                [ Effect.setSituation Dict.empty
                , Effect.setSimulationStep Shared.Model.Start
                ]
            )

        NoOp ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch
        [ Effect.onReactLinkClicked Shared.Msg.PushNewPath
        ]
