module Shared.Model exposing (Model, empty)

import Core.Evaluation exposing (Evaluation)
import Core.Personas exposing (Personas)
import Core.Results exposing (Results)
import Core.UI as UI
import Dict exposing (Dict)
import Json.Decode
import Publicodes exposing (RawRules)
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation exposing (Situation)
import Shared.EngineStatus as EngineStatus exposing (EngineStatus)
import Shared.SimulationStep as SimulationStep exposing (SimulationStep)


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
    , results : Maybe Results
    , engineStatus : EngineStatus
    , inputErrors : Dict RuleName { msg : String, value : String }
    , decodeError : Maybe Json.Decode.Error
    }


empty : Model
empty =
    { situation = Dict.empty
    , ui = UI.empty
    , rules = Dict.empty
    , simulationStep = SimulationStep.NotStarted
    , personas = Dict.empty
    , evaluations = Dict.empty
    , orderedCategories = []
    , results = Nothing
    , inputErrors = Dict.empty
    , engineStatus = EngineStatus.NotInitialized
    , decodeError = Nothing
    }
