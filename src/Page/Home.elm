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
    div []
        [ div [ class "fr-container bg-[var(--background-default-grey)] py-16 md:py-32" ]
            [ div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
                [ div [ class "fr-col-md-6" ]
                    [ h1 [] [ text "Comparer les coûts et les émissions de votre voiture" ]
                    , p [ class "fr-text--lg" ]
                        [ text "En "
                        , span [ class "fr-text--bold text-[var(--text-default-info)]" ] [ text "moins de 5 minutes" ]
                        , text """, découvrez les coûts et
                    les émissions de votre voiture et comparez-les aux
                    alternatives afin de faire un choix éclairé.
                    """
                        ]
                    , Button.new
                        { label = ctaLabel
                        , onClick = Nothing
                        }
                        |> Button.linkButton (Url.Builder.absolute Page.Simulateur.path [])
                        |> Button.withAttrs [ class "" ]
                        |> Button.large
                        |> Button.view
                    ]
                , div [ class "fr-col-md-4 hidden md:block" ]
                    [ img
                        [ src "/undraw_order_a_car.svg"
                        , alt "Illustration d'une voiture"
                        , class "px-12"
                        ]
                        []
                    ]
                ]
            ]
        , div [ class "bg-[var(--background-alt-grey)] py-6" ]
            [ div [ class "fr-container" ]
                [ span []
                    [ text "Aucune donnée n'est collectée, tout est calculé dans votre navigateur. Le détail du calcul est disponible dans la "
                    , a [ href "/documentation" ] [ text "documentation" ]
                    , text "."
                    ]
                ]
            ]
        ]
