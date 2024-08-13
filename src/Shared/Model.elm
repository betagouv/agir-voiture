module Shared.Model exposing
    ( Model
    , SimulationStep(..)
    , empty
    , simulationStepDecoder
    , simulationStepEncode
    )

import Core.Personas exposing (Personas)
import Core.UI as UI
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Publicodes exposing (RawRules)
import Publicodes.Situation exposing (Situation)


{-| Contains all the data shared between the different pages of the application.


## Note

Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type alias Model =
    { rules : RawRules
    , ui : UI.Data
    , personas : Personas
    , situation : Situation
    , simulationStep : SimulationStep
    }


empty : Model
empty =
    { situation = Dict.empty
    , ui = UI.empty
    , rules = Dict.empty
    , simulationStep = Start
    , personas = Dict.empty
    }



-- SIMULATION STEP


{-| Represents the current step of the simulation.

For now, the `Start` step is not used and act like a `Nothing` value. We may
want to use it to display information about the questions that will be asked
before starting.

-}
type SimulationStep
    = Start
    | Category UI.Category
    | Result


simulationStepDecoder : Decode.Decoder SimulationStep
simulationStepDecoder =
    Decode.map
        (\s ->
            case s of
                "Result" ->
                    Result

                "Start" ->
                    Start

                _ ->
                    Category s
        )
        Decode.string


simulationStepEncode : SimulationStep -> Encode.Value
simulationStepEncode step =
    case step of
        Category category ->
            Encode.string category

        Result ->
            Encode.string "Result"

        Start ->
            Encode.string "Start"
