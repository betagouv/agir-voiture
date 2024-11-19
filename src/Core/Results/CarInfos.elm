module Core.Results.CarInfos exposing (CarInfos, decoder)

import Core.Results.RuleValue as RuleValue exposing (RuleValue)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)


type alias CarInfos =
    { title : Maybe String
    , cost : RuleValue Float
    , emissions : RuleValue Float
    , size : RuleValue String
    , motorisation : RuleValue String
    , fuel : Maybe (RuleValue String)
    }


decoder : Decode.Decoder CarInfos
decoder =
    Decode.succeed CarInfos
        |> optional "title" (Decode.nullable Decode.string) Nothing
        |> required "cost" (RuleValue.decoderWith Decode.float)
        |> required "emissions" (RuleValue.decoderWith Decode.float)
        |> required "size" (RuleValue.decoderWith Decode.string)
        |> required "motorisation" (RuleValue.decoderWith Decode.string)
        |> required "fuel" (Decode.nullable (RuleValue.decoderWith Decode.string))
