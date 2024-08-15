module Components.Select exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


view :
    { label : String
    , onInput : String -> msg
    , options : List option
    , selected : option
    , toValue : option -> String
    , toLabel : option -> Html msg
    }
    -> Html msg
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
                    (\val ->
                        option
                            [ value (props.toValue val)
                            , selected (props.selected == val)
                            ]
                            [ props.toLabel val ]
                    )
            )
        ]
