module Page.Home exposing (Model, Msg(..), init, update, view)

import BetaGouv.DSFR.Button as Button
import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation exposing (pushUrl)
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.Simulateur
import Session exposing (SimulationStep(..))
import Url.Builder


type alias Model =
    { session : Session.Data
    }


init : Session.Data -> ( Model, Cmd Msg )
init session =
    ( { session = session
      }
    , Cmd.none
    )


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view { session } =
    let
        ctaLabel =
            case session.simulationStep of
                Start ->
                    "Démarrer"

                Category _ ->
                    "Reprendre ma simulation"

                Result ->
                    "Voir mes résultats"
    in
    div [ class "fr-container bg-[var(--background-default-grey)] md:py-8" ]
        [ div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
            [ div [ class "fr-col-lg-6" ]
                [ h1 [] [ text "Comparer les coûts et les émissions de votre voiture" ]
                , div [ class "fr-text--lead" ]
                    [ text """
                    En répondant à quelques questions, vous pourrez comparer
                    les coûts et les émissions de votre voiture avec d'autres
                    types de véhicules.
                    """
                    ]
                , Button.new
                    { label = ctaLabel
                    , onClick = Nothing
                    }
                    |> Button.linkButton (Url.Builder.absolute Page.Simulateur.path [])
                    |> Button.view
                ]
            , img
                [ src "/undraw_order_a_car.svg"
                , alt "Illustration d'une voiture"
                , class "fr-col-lg-4 p-12"
                ]
                []
            ]
        ]
