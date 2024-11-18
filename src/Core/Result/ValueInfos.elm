module Core.Result.ValueInfos exposing (ValueInfos, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)


type alias ValueInfos =
    { -- TODO: Maybe is not sufficient, we should be able to distinguish between
      -- a "non applicable" value (null) and a "non définie" value (undefined).
      nodeValue : Maybe String
    , unit : Maybe String
    , title : Maybe String
    }


decoder : Decoder ValueInfos
decoder =
    Decode.succeed ValueInfos
        |> required "nodeValue" (Decode.maybe Decode.string)
        |> required "unit" (Decode.maybe Decode.string)
        |> required "title" (Decode.maybe Decode.string)
