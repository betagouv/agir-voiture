module Components.Simulateur.BooleanInput exposing (view)

import BetaGouv.DSFR.Radio
import Html exposing (..)
import Html.Attributes exposing (..)
import Publicodes.NodeValue as NodeValue


view :
    { id : String
    , label : Html msg
    , current : NodeValue.NodeValue
    , onChecked : NodeValue.NodeValue -> msg
    }
    -> Html msg
view props =
    BetaGouv.DSFR.Radio.group
        { id = props.id
        , legend = props.label
        , options = [ NodeValue.Boolean True, NodeValue.Boolean False ]
        , toId = NodeValue.toString
        , toLabel = NodeValue.toString >> text
        , current = Just props.current
        , toValue = NodeValue.toString
        , onChecked = props.onChecked
        }
        |> BetaGouv.DSFR.Radio.view