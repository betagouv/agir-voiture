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
    let
        titleId =
            "modal-title-" ++ props.id
    in
    node "dialog"
        [ id props.id, class "max-w-xl", labelledBy titleId, role "dialog" ]
        [ div [ class "" ]
            [ div [ class "fr-grid-row fr-grid-row--center" ]
                [ div [ class "" ]
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
                            [ h1 [ id titleId, class "fr-modal__title" ]
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
