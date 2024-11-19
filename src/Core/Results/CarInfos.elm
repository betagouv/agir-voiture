module Core.Results.CarInfos exposing (CarInfos, decoder)

import Core.Results.RuleValue as RuleValue exposing (RuleValue)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)


type alias CarInfos =
    { title : Maybe String
    , cost : RuleValue
    , emissions : RuleValue
    , size : RuleValue
    , motorisation : RuleValue
    , fuel : RuleValue
    }


decoder : Decode.Decoder CarInfos
decoder =
    Decode.succeed CarInfos
        |> optional "title" (Decode.nullable Decode.string) Nothing
        |> required "cost" RuleValue.decoder
        |> required "emissions" RuleValue.decoder
        |> required "size" RuleValue.decoder
        |> required "motorisation" RuleValue.decoder
        |> required "fuel" RuleValue.decoder
