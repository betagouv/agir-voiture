module Components.Select exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type alias Props msg =
    { label : String
    , onInput : String -> msg
    , options : List ( String, String )
    , selected : String
    }


view : Props msg -> Html msg
view props =
    div [ class "fr-select-group" ]
        [ Html.label [ class "fr-label", for "select" ]
            [ text props.label ]
        , select
            [ onInput (\v -> props.onInput v)
            , class "fr-select"
            , id "select"
            , name "select"
            ]
            (props.options
                |> List.map
                    (\( optionValue, optionLabel ) ->
                        option
                            [ value optionValue
                            , selected (props.selected == optionValue)
                            ]
                            [ text optionLabel ]
                    )
            )
        ]
