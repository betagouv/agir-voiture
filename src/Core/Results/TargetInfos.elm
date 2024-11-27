module Core.Results.TargetInfos exposing (TargetInfos, decoder)

import Core.Results.RuleValue as RuleValue exposing (RuleValue)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)


type alias TargetInfos =
    { size : RuleValue String
    , hasChargingStation : RuleValue Bool
    }


decoder : Decode.Decoder TargetInfos
decoder =
    Decode.succeed TargetInfos
        |> required "size" (RuleValue.decoderWith Decode.string)
        |> required "hasChargingStation" (RuleValue.decoderWith Decode.bool)
