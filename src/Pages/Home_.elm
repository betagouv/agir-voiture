module Pages.Home_ exposing (Model, Msg, page)

import BetaGouv.DSFR.Button as Button
import Effect exposing (Effect)
import Html exposing (a, div, h1, img, p, span, text)
import Html.Attributes exposing (alt, class, href, src)
import Layouts
import Main.Layouts.Model exposing (Model)
import Page exposing (Page)
import Pages.Simulateur exposing (Msg)
import Route exposing (Route)
import Route.Path
import Shared
import Shared.SimulationStep exposing (SimulationStep(..))
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared _ =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view shared
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout _ =
    Layouts.HeaderAndFooter { showReactRoot = False, contrastBg = False }



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
    { title = "Accueil - Mes options de mobilité durable - J'agis"
    , body =
        let
            ctaLabel =
                case shared.simulationStep of
                    NotStarted ->
                        "Démarrer"

                    Category _ ->
                        "Reprendre ma simulation"

                    Result ->
                        "Voir mes résultats"
        in
        [ div [ class "fr-container bg-[var(--background-default-grey)] fr-py-16 md:pt-24 md:pb-32" ]
            [ div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
                [ div [ class "fr-col-md-6" ]
                    [ h1 [] [ text "Quelle est la meilleure option pour votre situation ?" ]
                    , p [ class "fr-text--lg" ]
                        [ text "En "
                        , span [ class "fr-text--bold text-[var(--text-default-info)]" ] [ text "moins de 5 minutes" ]
                        , text ", estimez "
                        , span [ class "fr-text--bold" ] [ text "les coûts et les émissions" ]
                        , text " de votre voiture et "
                        , span [ class "fr-text--bold" ] [ text "comparez-les à des alternatives" ]
                        , text " économiques et écologiques pour une "
                        , span [ class "fr-text--bold" ] [ text "mobilité plus durable" ]
                        , text "."
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
