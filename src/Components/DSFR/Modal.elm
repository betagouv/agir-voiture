module Components.DSFR.Modal exposing (..)

import Accessibility.Aria exposing (labelledBy)
import BetaGouv.DSFR.Button as Button
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (role)


{-| Minimal modal component for the DSFR.

FIXME: using the `fr-modal` in dev mode isn't working.

-}
view : { id : String, title : String, content : Html msg, onClose : msg } -> Html msg
view props =
    node "dialog"
        [ id props.id, class "fr-modal", labelledBy "modal-title", role "dialog" ]
        [ div [ class "fr-container fr-container--fluid fr-container-md w-full" ]
            [ div [ class "fr-grid-row fr-grid-row--center" ]
                [ div [ class "fr-col-12 fr-col-md-8 fr-col-lg-6" ]
                    [ div [ class "fr-modal__body" ]
                        [ div [ class "fr-modal__header" ]
                            [ Button.new
                                { label = "Fermer"
                                , onClick = Just props.onClose
                                }
                                |> Button.close
                                |> Button.view
                            ]
                        , div [ class "fr-modal__content" ]
                            [ h1 [ id "modal-title", class "fr-modal__title" ]
                                [ span [ class "fr-icon-arrow-right-line fr-icon--lg" ] []
                                , text props.title
                                ]
                            , props.content
                            ]
                        ]
                    ]
                ]
            ]
        ]
