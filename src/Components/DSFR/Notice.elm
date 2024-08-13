module Components.DSFR.Notice exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)


view : { title : String, desc : Html msg } -> Html msg
view { title, desc } =
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
