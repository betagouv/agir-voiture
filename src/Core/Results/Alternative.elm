module Core.Results.Alternative exposing (..)

import Core.Results.CarInfos as CarInfos exposing (CarInfos)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)


type Alternative
    = BuyNewCar CarInfos
    | KeepCurrentCar CarInfos


decoder : Decoder Alternative
decoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen
            (\kind ->
                case kind of
                    "buy-new-car" ->
                        CarInfos.decoder
                            |> Decode.map BuyNewCar

                    "keep-current-car" ->
                        CarInfos.decoder
                            |> Decode.map KeepCurrentCar

                    _ ->
                        Decode.fail <| "Unknown alternative kind: " ++ kind
            )


getCarInfos : Alternative -> CarInfos
getCarInfos alternative =
    case alternative of
        BuyNewCar carInfos ->
            carInfos

        KeepCurrentCar carInfos ->
            carInfos
