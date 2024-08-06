module Page.Template exposing (Config, view)

import Accessibility
import Accessibility.Aria as Aria exposing (labelledBy)
import BetaGouv.DSFR.Button as Button exposing (ButtonConfig)
import BetaGouv.DSFR.Icons as Icons
import BetaGouv.DSFR.Modal as Modal
import Browser exposing (Document)
import Components.DSFR.Notice
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (role)
import Html.Events exposing (..)
import Personas exposing (Personas)
import Publicodes as P
import Session as S


type alias Config msg =
    { title : String
    , content : Html msg
    , session : S.Data

    -- Show an empty div to mount React components and render custom elements.
    -- Currenlty, this is used to render the Publicodes documentation.
    , showReactRoot : Bool
    , resetSituation : msg
    , exportSituation : msg
    , importSituation : msg
    , openPersonasModal : msg
    , closePersonasModal : msg
    , setPersonaSituation : P.Situation -> msg
    }


view : Config msg -> Document msg
view config =
    let
        ( personasModal, _ ) =
            Modal.view
                { id = "personas-modal"
                , label = "Choissir un profil type"
                , openMsg = config.openPersonasModal
                , closeMsg = Just config.closePersonasModal
                , title = text "Choississez un profil type"
                , opened = config.session.personasModalOpened
                }
                (viewPersonas config.session.personas config.setPersonaSituation)
                Nothing
    in
    { title = config.title ++ " | Agir - Simulateur voiture"
    , body =
        [ viewHeader config
        , Components.DSFR.Notice.view
            { title = "En cours de développement"
            , desc = text "Les résultats de ce simulateur ne sont pas stables et sont susceptibles de fortement évoluer."
            }
        , personasModal
        , if config.showReactRoot then
            div [ class "fr-container" ]
                [ div [ id "react-root" ] []
                ]

          else
            text ""
        , main_ []
            [ if Dict.isEmpty config.session.rawRules then
                div [ class "flex flex-col w-full h-full items-center" ]
                    [ S.viewError config.session.currentErr
                    , div [ class "loading loading-lg text-primary mt-4" ] []
                    ]

              else
                config.content
            ]
        , viewFooter
        ]
    }


viewHeader : Config msg -> Html msg
viewHeader config =
    header [ role "banner", class "fr-header" ]
        [ div [ class "fr-header__body" ]
            [ div [ class "fr-container" ]
                [ div [ class "fr-header__body-row" ]
                    [ div [ class "fr-header__brand fr-enlarge-link" ]
                        [ div [ class "fr-header__brand-top" ]
                            [ div [ class "fr-header__operator" ]
                                [ a [ href "/" ]
                                    [ img
                                        [ class "fr-responsive-img"
                                        , style "max-width" "9.0625rem;"
                                        , src "/logo.svg"
                                        , alt "Revenir à la page d'accueil"
                                        ]
                                        []
                                    ]
                                ]
                            ]
                        , div [ class "fr-header__service" ]
                            [ a [ href "/", title "Accueil - Comparateur Voiture - Agir" ]
                                [ p [ class "fr-header__service-title" ]
                                    [ text "Comparateur Voiture"
                                    ]
                                ]
                            , p [ class "fr-header__service-description" ]
                                [ text "Estimer les coûts de votre voiture"
                                ]
                            ]
                        ]
                    , div [ class "fr-header__tools" ]
                        [ div [ class "fr-header__tools-links" ]
                            [ [ Button.new
                                    { label = "Choisir un profil type"
                                    , onClick = Just config.openPersonasModal
                                    }
                                    |> Button.leftIcon Icons.user.accountCircleLine
                                    |> Button.withAttrs [ Aria.controls [ "personas-modal" ] ]
                              , Button.new
                                    { label = "Réinitialiser"
                                    , onClick = Just config.resetSituation
                                    }
                                    |> Button.leftIcon Icons.system.refreshLine
                              , Button.new
                                    { label = "Comprendre le calcul"
                                    , onClick = Nothing
                                    }
                                    |> Button.linkButton "documentation"
                                    |> Button.leftIcon Icons.document.fileTextLine
                              ]
                                |> Button.group
                                |> Button.viewGroup
                            ]
                        ]
                    ]
                ]
            ]
        ]


viewPersonas : Personas -> (P.Situation -> msg) -> Accessibility.Html msg
viewPersonas personas setPersonaSituation =
    (personas
        |> Dict.toList
        |> List.map
            (\( _, persona ) ->
                Button.new
                    { label = persona.titre
                    , onClick = Just (setPersonaSituation persona.situation)
                    }
                    |> Button.secondary
            )
    )
        |> Button.group
        |> Button.viewGroup


viewFooter : Html msg
viewFooter =
    div []
        []
