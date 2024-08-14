module Shared.SimulationStep exposing (SimulationStep(..), decode, decoder, encode)

{-| Represents the current step of the simulation.

For now, the `NotStarted` step is not used and act like a `Nothing` value. We may
want to use it to display information about the questions that will be asked
before starting.

-}

import Core.UI
import Json.Decode as Decode
import Json.Encode as Encode


type SimulationStep
    = NotStarted
    | Category Core.UI.Category
    | Result


decoder : Decode.Decoder SimulationStep
decoder =
    Decode.map
        (\s ->
            case s of
                "Result" ->
                    Result

                "NotStarted" ->
                    NotStarted

                _ ->
                    Category s
        )
        Decode.string


decode : Encode.Value -> Result Decode.Error SimulationStep
decode value =
    Decode.decodeValue decoder value


encode : SimulationStep -> Encode.Value
encode step =
    case step of
        Category category ->
            Encode.string category

        Result ->
            Encode.string "Result"

        NotStarted ->
            Encode.string "NotStarted"
