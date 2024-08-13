module Components.DSFR.Header exposing (new, view)

import Accessibility.Aria as Aria
import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.Icons as Icons
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (role)


type Header msg
    = Settings
        { onReset : msg
        , onPersonasModalOpen : msg
        }


new : { onReset : msg, onPersonasModalOpen : msg } -> Header msg
new props =
    Settings props


view : Header msg -> Html msg
view (Settings settings) =
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
                                    , onClick = Just settings.onPersonasModalOpen
                                    }
                                    |> Button.leftIcon Icons.user.accountCircleLine
                                    |> Button.withAttrs [ Aria.controls [ "personas-modal" ] ]
                              , Button.new
                                    { label = "Recommencer"
                                    , onClick = Just settings.onReset
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
