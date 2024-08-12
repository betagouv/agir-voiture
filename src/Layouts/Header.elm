module Layouts.Header exposing (Model, Msg, Props, layout)

import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (viewIf)
import Layout exposing (Layout)
import Route exposing (Route)
import Shared
import View exposing (View)


type alias Props =
    { showReactRoot : Bool
    }


layout : Props -> Shared.Model -> Route () -> Layout () Model Msg contentMsg
layout props _ _ =
    Layout.new
        { init = init
        , update = update
        , view = view props
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    ()


init : () -> ( Model, Effect Msg )
init _ =
    ( (), Effect.none )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model
            , Effect.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Props -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model } -> View contentMsg
view props { content } =
    { title = content.title
    , body =
        [ viewIf props.showReactRoot viewReactRoot
        , div [ class "page" ] content.body
        ]
    }


viewReactRoot : Html msg
viewReactRoot =
    div
        [ class "fr-container" ]
        [ div [ id "react-root" ] []
        ]
