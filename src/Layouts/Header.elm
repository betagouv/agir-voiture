module Layouts.Header exposing (Model, Msg, Props, layout)

import Components.DSFR.Header
import Components.DSFR.Notice
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (viewIf)
import Layout exposing (Layout)
import Route exposing (Route)
import Shared
import Shared.Msg exposing (Msg(..))
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
    = ResetSimulation


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ResetSimulation ->
            ( model, Effect.resetSimulation )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Props -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model } -> View contentMsg
view props { content, toContentMsg } =
    { title = content.title
    , body =
        [ viewIf props.showReactRoot viewReactRoot
        , Components.DSFR.Header.new { onReset = ResetSimulation }
            |> Components.DSFR.Header.view
            |> Html.map toContentMsg
        , Components.DSFR.Notice.view
            { title = "En cours de développement"
            , desc = text "Les résultats de ce simulateur ne sont pas stables et sont susceptibles de fortement évoluer."
            }
        , div [ class "page" ] content.body
        ]
    }


viewReactRoot : Html msg
viewReactRoot =
    div
        [ class "fr-container" ]
        [ div [ id "react-root" ] []
        ]
