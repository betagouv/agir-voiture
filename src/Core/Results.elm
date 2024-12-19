module Core.Results exposing (ResultType(..), Results, decoder)

import Core.Results.CarInfos as CarInfos exposing (CarInfos)
import Core.Results.TargetInfos as TargetInfos exposing (TargetInfos)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)


type alias Results =
    { user : CarInfos
    , -- TODO: must be refactored with a more generic type when other
      -- alternatives will be introduced
      alternatives : List CarInfos
    , target : Maybe TargetInfos
    }


decoder : Decode.Decoder Results
decoder =
    Decode.succeed Results
        |> required "user" CarInfos.decoder
        |> required "alternatives" (Decode.list CarInfos.decoder)
        |> required "target" (Decode.nullable TargetInfos.decoder)


type ResultType
    = Cost
    | Emissions
