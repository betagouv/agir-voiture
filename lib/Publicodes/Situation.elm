module Publicodes.Situation exposing (Situation, decoder, encode)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)


type alias Situation =
    Dict RuleName NodeValue


decoder : Decoder Situation
decoder =
    Decode.dict NodeValue.decoder


encode : Situation -> Encode.Value
encode situation =
    Encode.dict identity NodeValue.encode situation
