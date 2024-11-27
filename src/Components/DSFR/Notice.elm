module Components.DSFR.Notice exposing (alert, info)

import Html exposing (..)
import Html.Attributes exposing (..)


info : { title : String, desc : Html msg } -> Html msg
info { title, desc } =
    div [ class "fr-notice fr-notice--info" ]
        [ div [ class "fr-container" ]
            [ div [ class "fr-notice__body" ]
                [ p []
                    [ span [ class "fr-notice__title" ] [ text title ]
                    , span [ class "fr-notice__desc" ] [ desc ]
                    ]
                ]
            ]
        ]


alert : { title : String, desc : Html msg } -> Html msg
alert { title, desc } =
    div [ class "fr-notice fr-notice--alert" ]
        [ div [ class "fr-container" ]
            [ div [ class "fr-notice__body" ]
                [ p []
                    [ span [ class "fr-notice__title" ] [ text title ]
                    , span [ class "fr-notice__desc" ] [ desc ]
                    ]
                ]
            ]
        ]
