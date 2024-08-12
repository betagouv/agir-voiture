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

import Effect exposing (Effect)
import Interop
import Json.Decode
import Json.Decode.Pipeline as Decode
import Publicodes exposing (RawRules)
import Publicodes.Situation as Situation exposing (Situation)
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg



-- FLAGS


type alias Flags =
    { rules : RawRules
    , situation : Situation
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.succeed Flags
        |> Decode.required "rules" Publicodes.rawRulesDecoder
        |> Decode.required "situation" Situation.decoder



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult _ =
    case flagsResult of
        Ok flags ->
            ( { situation = flags.situation
              , rules = flags.rules
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
        Shared.Msg.PushNewPath stringPath ->
            let
                path =
                    Route.Path.fromString stringPath
                        |> Maybe.withDefault Route.Path.NotFound_
            in
            ( model
            , Effect.pushRoutePath path
            )

        Shared.Msg.NoOp ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions _ _ =
    Sub.batch
        [ Interop.onReactLinkClicked Shared.Msg.PushNewPath
        ]
