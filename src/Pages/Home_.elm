module Pages.Home_ exposing (Model, Msg, page)

import BetaGouv.DSFR.Button as Button
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Main.Layouts.Model exposing (Model)
import Page exposing (Page)
import Pages.Simulateur exposing (Msg)
import Route exposing (Route)
import Route.Path
import Shared
import Shared.Model exposing (SimulationStep(..))
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared _ =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init () =
    ( {}
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


view : Shared.Model -> Model -> View Msg
view shared _ =
    { title = "Accueil - Quelle voiture choisir ?"
    , body =
        let
            ctaLabel =
                case shared.simulationStep of
                    Start ->
                        "Démarrer"

                    Category _ ->
                        "Reprendre ma simulation"

                    Result ->
                        "Voir mes résultats"
        in
        [ div [ class "fr-container bg-[var(--background-default-grey)] py-16 md:py-32" ]
            [ div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
                [ div [ class "fr-col-md-6" ]
                    [ h1 [] [ text "Comparer les coûts et les émissions de votre voiture" ]
                    , p [ class "fr-text--lg" ]
                        [ text "En "
                        , span [ class "fr-text--bold text-[var(--text-default-info)]" ] [ text "moins de 5 minutes" ]
                        , text """, découvrez les coûts et
                    les émissions de votre voiture et comparez-les aux
                    alternatives afin de faire un choix éclairé pour une mobilité plus durable.
                    """
                        ]
                    , Button.new
                        { label = ctaLabel
                        , onClick = Nothing
                        }
                        |> Button.linkButton (Route.Path.toString Route.Path.Simulateur)
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
    }
