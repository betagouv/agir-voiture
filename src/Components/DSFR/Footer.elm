module Components.DSFR.Footer exposing (view)

import Accessibility.Landmark exposing (contentInfo)
import Html exposing (..)
import Html.Attributes exposing (..)
import Route.Path


view : Html msg
view =
    footer [ id "footer", class "fr-footer", contentInfo ]
        [ div [ class "fr-container" ]
            [ div [ class "fr-footer__body" ]
                [ div [ class "fr-footer__brand fr-enlarge-link" ]
                    [ p [ class "fr-logo" ]
                        [ text "République"
                        , br [] []
                        , text "française"
                        ]
                    , a [ class "fr-footer__brand-link", href "/", title "Retour à l'accueil" ]
                        [ img
                            [ src "/logo_fnv.png"
                            , alt "Logo France Nation Verte"
                            , class "fr-footer__logo"
                            , style "width" "5.5rem"
                            ]
                            []
                        ]
                    ]
                , div [ class "fr-footer__content" ]
                    [ p [ class "fr-footer__content-desc" ]
                        [ text "Ce site est développé dans le câdre du projet "
                        , a [ href "https://jagis.beta.gouv.fr", target "_blank", rel "noopener external" ]
                            [ text "France Nation Verte / J'agis" ]
                        , text " au sein de "
                        , a [ href "https://beta.gouv.fr/incubateurs/dinum", target "_blank", rel "noopener external" ]
                            [ text "L'Incubateur du Service Numérique (DINUM)" ]
                        , text ". Il est financé par le Secrétariat général à la planification écologique (SGPE) via le "
                        , a [ href "https://www.numerique.gouv.fr/services/fonds-dinvestissement-numerique-et-donnees-pour-la-planification-ecologique/", target "_blank", rel "noopener external" ]
                            [ text "Fonds d’investissement Numérique et Données pour la Planification écologique (FINDPE)" ]
                        , text "."
                        ]
                    , ul [ class "fr-footer__content-list" ]
                        [ li [ class "fr-footer__content-item" ]
                            [ viewExternalLink
                                { name = "info.gouv.fr"
                                , url = "https://info.gouv.fr"
                                , className = "fr-footer__content-link"
                                , label = "info.gouv.fr"
                                }
                            ]
                        , li [ class "fr-footer__content-item" ]
                            [ viewExternalLink
                                { name = "service-public.fr"
                                , url = "https://service-public.fr"
                                , className = "fr-footer__content-link"
                                , label = "service-public.fr"
                                }
                            ]
                        , li [ class "fr-footer__content-item" ]
                            [ viewExternalLink
                                { name = "legifrance.gouv.fr"
                                , url = "https://legifrance.gouv.fr"
                                , className = "fr-footer__content-link"
                                , label = "legifrance.gouv.fr"
                                }
                            ]
                        , li [ class "fr-footer__content-item" ]
                            [ viewExternalLink
                                { name = "data.gouv.fr"
                                , url = "https://data.gouv.fr"
                                , className = "fr-footer__content-link"
                                , label = "data.gouv.fr"
                                }
                            ]
                        ]
                    ]
                ]
            , div [ class "fr-footer__bottom" ]
                [ ul [ class "fr-footer__bottom-list" ]
                    [ li [ class "fr-footer__bottom-item" ]
                        [ viewInternalLink
                            { name = "documentation interactive"
                            , path = Route.Path.Documentation
                            , className = "fr-footer__bottom-link"
                            , label = "Explorer le modèle de calcul"
                            }
                        ]
                    , li [ class "fr-footer__bottom-item" ]
                        [ viewExternalLink
                            { name = "github"
                            , url = "https://github.com/betagouv/agir-voiture"
                            , className = "fr-footer__bottom-link"
                            , label = "Code source du site"
                            }
                        ]
                    ]
                , div [ class "fr-footer__bottom-copy" ]
                    [ p []
                        [ text "Sauf mention contraire, le contenu de ce site est placé sous licence "
                        , a
                            [ href "https://github.com/betagouv/agir-voiture/blob/main/LICENSE"
                            , target "_blank"
                            , rel "noopener external"
                            , title "Licence etalab - nouvelle fenêtre"
                            ]
                            [ text "Apache 2.0" ]
                        ]
                    ]
                ]
            ]
        ]


viewExternalLink :
    { name : String
    , url : String
    , className : String
    , label : String
    }
    -> Html msg
viewExternalLink props =
    a
        [ target "_blank"
        , rel "noopener external"
        , title (props.name ++ " - nouvelle fenêtre")
        , id ("footer-link-" ++ props.name)
        , href props.url
        , class props.className
        ]
        [ text props.label
        ]


viewInternalLink :
    { name : String
    , path : Route.Path.Path
    , className : String
    , label : String
    }
    -> Html msg
viewInternalLink props =
    a
        [ title (props.name ++ " - nouvelle fenêtre")
        , id ("footer-link-" ++ props.name)
        , href (Route.Path.toString props.path)
        , class props.className
        ]
        [ text props.label
        ]
