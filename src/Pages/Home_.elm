module Pages.Home_ exposing (page)

import Html exposing (div, h1, text)
import Html.Attributes exposing (class)
import View exposing (View)


page : View msg
page =
    { title = "Homepage"
    , body =
        [ div [ class "fr-container bg-[var(--background-default-grey)]" ]
            [ h1 [ class "text-[var(--text-default-info)]" ]
                [ text "Hello, world!"
                ]
            ]
        ]
    }
