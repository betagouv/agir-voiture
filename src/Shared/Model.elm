module Shared.Model exposing (Model, empty)

import Core.Personas exposing (Personas)
import Core.UI as UI
import Dict exposing (Dict)
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation exposing (Situation)
import Shared.SimulationStep exposing (SimulationStep(..))


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
    , inputErrors : Dict RuleName { msg : String, value : String }
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
