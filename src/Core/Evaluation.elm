module Core.Evaluation exposing (Evaluation, decoder)

import Json.Decode as Decode exposing (nullable)
import Json.Decode.Pipeline exposing (required)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)


type alias Evaluation =
    { value : NodeValue
    , unit : Maybe String
    , isApplicable : Bool
    , title : Maybe String
    , isEnumValue : Bool
    }


decoder : Decode.Decoder Evaluation
decoder =
    Decode.succeed Evaluation
        |> required "value" NodeValue.decoder
        |> required "unit" (nullable Decode.string)
        |> required "isApplicable" Decode.bool
        |> required "title" (nullable Decode.string)
        |> required "isEnumValue" Decode.bool
