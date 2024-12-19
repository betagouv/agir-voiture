module Components.Select exposing (view)

import Html exposing (Html, div, label, option, select, span, text)
import Html.Attributes exposing (class, for, id, name, selected, value)
import Html.Events exposing (onInput)
import Html.Extra exposing (viewMaybe)


view :
    { id : String
    , label : String
    , onInput : String -> msg
    , options : List option
    , selected : option
    , toValue : option -> String
    , toLabel : option -> Html msg
    , hint : Maybe String
    }
    -> Html msg
view props =
    div [ class "fr-select-group" ]
        [ label [ class "fr-label", for props.id ]
            [ text props.label
            , span [ class "fr-hint-text" ]
                [ viewMaybe text props.hint ]
            ]
        , select
            [ onInput (\v -> props.onInput v)
            , class "fr-select"
            , id props.id
            , name "select"
            ]
            (props.options
                |> List.map
                    (\val ->
                        option
                            [ id (props.id ++ "--" ++ props.toValue val)
                            , value (props.toValue val)
                            , selected (props.selected == val)
                            ]
                            [ props.toLabel val ]
                    )
            )
        ]
