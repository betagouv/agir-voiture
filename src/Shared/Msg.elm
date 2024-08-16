module Shared.Msg exposing (Msg(..))

{-| -}

import Publicodes exposing (Evaluation)
import Publicodes.NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation exposing (Situation)
import Shared.SimulationStep exposing (SimulationStep)


{-| Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type Msg
    = NoOp
    | PushNewPath String
    | SetSimulationStep SimulationStep
    | ResetSimulation
    | NewEvaluations (List ( RuleName, Evaluation ))
    | SetSituation Situation
    | UpdateSituation ( RuleName, NodeValue )
    | Evaluate
    | NewInputError { name : RuleName, value : String, msg : String }
    | RemoveInputError RuleName
    | EngineInitialized (Maybe String)
