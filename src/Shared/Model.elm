module Shared.Model exposing (Model, empty)

import Dict
import Publicodes exposing (RawRules)
import Publicodes.Situation exposing (Situation)


{-| Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type alias Model =
    { situation : Situation
    , rules : RawRules
    }


empty : Model
empty =
    { situation = Dict.empty
    , rules = Dict.empty
    }
