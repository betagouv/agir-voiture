module Pages.Documentation exposing (Model, Msg, page)

import Components.DSFR.Card as Card
import Core.Rules
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Layouts
import Markdown
import Page exposing (Page)
import Publicodes exposing (RawRules)
import Publicodes.Helpers
import Publicodes.RuleName as RuleName exposing (RuleName)
import Route exposing (Route)
import Route.Path
import Shared
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
    Layouts.Header { showReactRoot = False }



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



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared _ =
    { title = "Documentation - Quelle voiture choisir ?"
    , body =
        [ -- TODO: extract this in a layout?
          div [ class "fr-container fr-py-18v flex justify-center" ]
            [ div [ class "fr-grid-row fr-grid-row--gutters fr-col-md-8" ]
                [ h1 [] [ text "Documentation" ]
                , section [ class "" ]
                    [ p []
                        [ text """
                Ce simulateur est basé sur un modèle de calcul créé à partir de
                deux modèle de calculs existants :
                """
                        , ul []
                            [ li []
                                [ text "le simulateur de l'ADEME "
                                , a [ href "https://nosgestesclimat.fr", target "_blank" ] [ text "Nos Gestes Climat" ]
                                , text " pour le calcul des émissions de CO2e d'un véhicule ;"
                                ]
                            , li []
                                [ text "le simulateur "
                                , a [ href "https://futur.eco", target "_blank" ] [ text "Futur.eco" ]
                                , text " pour le calcul du coût d'un véhicule."
                                ]
                            ]
                        ]
                    , p []
                        [ text """
                        Vous pouvez explorer le détail du calcul en parcourant
                        la documentation intéractive (si vous avez déjà répondu
                        aux questions, les réponses seront reflétées dans la
                        documentation).
                        """
                        ]
                    , div [ class "fr-grid-row fr-grid-row--gutters " ]
                        [ div [ class "fr-col-12 fr-col-md-6" ]
                            [ viewCard Core.Rules.userCost shared.rules ]
                        , div [ class "fr-col-12 fr-col-md-6" ]
                            [ viewCard Core.Rules.userEmission shared.rules ]
                        ]
                    ]
                , section [ class "fr-mt-12v" ]
                    [ h2 [] [ text "Comment ça marche techniquement ?" ]
                    , p []
                        [ text "Le calcul derrière ce simulateur est implémenté en utilisant le langage de modélisation "
                        , a [ href "https://publi.codes", target "_blank" ] [ text "Publicodes" ]
                        , text "."
                        ]
                    , p []
                        [ text """
                    Ce choix a été fait pour d'une part permettre de facilement
                    réutiliser des briques de calculs existantes et d'autre
                    part pour bénéficier de la documentation intéractive
                    générée automatiquement. 
                    Cela nous semble être le minimum pour garantir la
                    transparence du calcul et permettre à chacun de comprendre
                    les hypothèses ainsi que les valeurs utilisées.
                    """
                        ]
                    ]
                ]
            ]
        ]
    }


viewCard : RuleName -> RawRules -> Html msg
viewCard rule rules =
    let
        title =
            Publicodes.Helpers.getTitle rule rules

        documentationPath =
            Route.Path.toString Route.Path.Documentation

        rulePath =
            RuleName.encodeToPath rule
    in
    Card.card (text title) Card.horizontal
        |> Card.withDescription (Just (text "Découvrez le détail du calcul"))
        |> Card.linkFull (documentationPath ++ "/" ++ rulePath)
        |> Card.withArrow True
        |> Card.view
