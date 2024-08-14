module Pages.Documentation.ALL_ exposing (Model, Msg, page)

import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (attribute)
import Json.Encode as Encode
import Layouts
import Page exposing (Page)
import Publicodes
import Publicodes.Helpers
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation
import Route exposing (Route)
import Shared
import Url
import View exposing (View)


page : Shared.Model -> Route { all_ : List String } -> Page Model Msg
page shared route =
    Page.new
        { init = \() -> init route.params.all_
        , update = update
        , subscriptions = subscriptions
        , view = view shared
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout _ =
    Layouts.Header { showReactRoot = True }



-- INIT


type alias Model =
    { rule : RuleName
    }


init : List String -> ( Model, Effect Msg )
init all_ =
    let
        decodedRuleName =
            all_
                |> -- NOTE: maybe we want to return an error if the rule name is not found
                   List.filterMap Url.percentDecode
                |> Publicodes.RuleName.join
                |> Publicodes.RuleName.decodeFromPath
    in
    ( { rule = decodedRuleName
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
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
        serializedSituation =
            Encode.encode 0 (Publicodes.Situation.encode shared.situation)

        ruleTitle =
            Publicodes.Helpers.getTitle model.rule shared.rules
    in
    { title = ruleTitle ++ " | Documentation"
    , body =
        [ node "publicodes-rule-page"
            [ attribute "rule" model.rule
            , attribute "documentationPath" "/documentation"
            , attribute "situation" serializedSituation
            ]
            []
        ]
    }
