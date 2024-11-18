module Core.Result.CarInfos exposing (CarInfos, decoder)

import Core.Result.ValueInfos as ValueInfos exposing (ValueInfos)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)


type alias CarInfos =
    { title : Maybe String
    , cost : Float
    , emissions : Float
    , size : ValueInfos
    , motorisation : ValueInfos
    , carburant : ValueInfos
    }


decoder : Decode.Decoder CarInfos
decoder =
    Decode.succeed CarInfos
        |> required "title" (Decode.maybe Decode.string)
        |> required "cost" Decode.float
        |> required "emissions" Decode.float
        |> required "size" ValueInfos.decoder
        |> required "motorisation" ValueInfos.decoder
        |> required "carburant" ValueInfos.decoder
