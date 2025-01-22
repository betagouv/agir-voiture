module Components.DSFR.Header exposing (Header, new, view)

import Accessibility.Aria as Aria
import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.Icons as Icons
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (role)
import Html.Events exposing (onClick)
import Route.Path


type Header msg
    = Settings
        { onReset : msg
        , onPersonasModalOpen : msg
        , onToggleHeaderMenu : msg
        , headerMenuIsOpen : Bool
        }


new :
    { onReset : msg
    , onPersonasModalOpen : msg
    , onToggleHeaderMenu : msg
    , headerMenuIsOpen : Bool
    }
    -> Header msg
new props =
    Settings props


modalMenuId : String
modalMenuId =
    "modal-menu"


modalMenuMobileTitle : String
modalMenuMobileTitle =
    "fr-btn-menu-mobile"


view : Header msg -> Html msg
view (Settings settings) =
    let
        buttonGroup =
            Button.group
                [ Button.new
                    { label = "Télécharger mes réponses"
                    , onClick = Just settings.onPersonasModalOpen
                    }
                    |> Button.leftIcon Icons.document.fileDownloadLine
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
                    |> Button.linkButton
                        (Route.Path.toString Route.Path.Documentation)
                    |> Button.leftIcon Icons.document.fileTextLine
                ]
    in
    header [ role "banner", class "fr-header" ]
        [ div [ class "fr-header__body" ]
            [ div [ class "fr-container" ]
                [ div [ class "fr-header__body-row" ]
                    [ div [ class "fr-header__brand fr-enlarge-link" ]
                        [ div [ class "fr-header__brand-top" ]
                            [ div [ class "fr-header__logo" ]
                                [ p [ class "fr-logo" ]
                                    [ text "République"
                                    , br [] []
                                    , text "Française"
                                    ]
                                ]
                            , div [ class "fr-header__operator" ]
                                [ img
                                    [ class "fr-responsive-img"
                                    , style "max-width" "5rem"
                                    , src "/logo.svg"
                                    , alt "Logo J'agis"
                                    ]
                                    []
                                ]
                            , div [ class "fr-header__navbar" ]
                                [ button
                                    [ class "fr-btn--menu fr-btn"
                                    , attribute "aria-controls" modalMenuId
                                    , attribute "aria-haspopup" "menu"
                                    , id modalMenuMobileTitle
                                    , onClick settings.onToggleHeaderMenu
                                    ]
                                    [ text "Menu" ]
                                ]
                            ]
                        , div [ class "fr-header__service" ]
                            [ a [ href "/", title "Accueil - Mes options de mobilité durable - J'agis" ]
                                [ p [ class "fr-header__service-title" ]
                                    [ text "Mes options de mobilité durable"
                                    , span [ class "fr-badge fr-badge--success fr-badge--no-icon fr-badge--sm fr-" ]
                                        [ text "Bêta" ]
                                    ]
                                ]
                            , p [ class "fr-header__service-description" ]
                                [ text "Comparez les coûts et les émissions de votre voiture"
                                ]
                            ]
                        ]
                    , div [ class "fr-header__tools" ]
                        [ div [ class "fr-header__tools-links" ]
                            [ Button.viewGroup buttonGroup
                            ]
                        ]
                    ]
                ]
            ]
        , div
            [ class "fr-header__menu fr-modal"
            , classList [ ( "fr-modal--opened", settings.headerMenuIsOpen ) ]
            , id modalMenuId
            , attribute "aria-labelledby" modalMenuMobileTitle
            ]
            [ div [ class "fr-container" ]
                [ button
                    [ class "fr-link--close fr-link"
                    , attribute "aria-controls" modalMenuId
                    , onClick settings.onToggleHeaderMenu
                    ]
                    [ text "Fermer" ]
                , div [ class "fr-header__menu-links" ]
                    [ Button.viewGroup buttonGroup
                    ]
                ]
            ]
        ]
