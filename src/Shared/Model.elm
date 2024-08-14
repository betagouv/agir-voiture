module Shared.Model exposing
    ( Model
    , SimulationStep(..)
    , empty
    , simulationStepDecode
    , simulationStepDecoder
    , simulationStepEncode
    )

import Core.Personas exposing (Personas)
import Core.UI as UI
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.RuleName exposing (RuleName)
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
    , evaluations : Dict RuleName Evaluation
    , orderedCategories : List UI.Category
    , resultRules : List RuleName
    , inputErrors : Dict RuleName String
    }


empty : Model
empty =
    { situation = Dict.empty
    , ui = UI.empty
    , rules = Dict.empty
    , simulationStep = NotStarted
    , personas = Dict.empty
    , evaluations = Dict.empty
    , orderedCategories = []
    , resultRules = []
    , inputErrors = Dict.empty
    }



-- SIMULATION STEP


{-| Represents the current step of the simulation.

For now, the `NotStarted` step is not used and act like a `Nothing` value. We may
want to use it to display information about the questions that will be asked
before starting.

-}
type SimulationStep
    = NotStarted
    | Category UI.Category
    | Result


simulationStepDecoder : Decode.Decoder SimulationStep
simulationStepDecoder =
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


simulationStepDecode : Encode.Value -> Result Decode.Error SimulationStep
simulationStepDecode value =
    Decode.decodeValue simulationStepDecoder value


simulationStepEncode : SimulationStep -> Encode.Value
simulationStepEncode step =
    case step of
        Category category ->
            Encode.string category

        Result ->
            Encode.string "Result"

        NotStarted ->
            Encode.string "NotStarted"
