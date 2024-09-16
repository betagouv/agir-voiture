module Publicodes.Helpers exposing (getTitle, getUnit, mechanismToFloat)

{-| Get the title of a rule from its name.
If the rule doesn't have a title, the name is returned.
-}

import Dict
import Publicodes exposing (Mechanism(..), RawRules)
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName exposing (RuleName)


{-| Get the title of a rule from its name.
If the rule doesn't have a title, the name is returned.
-}
getTitle : RuleName -> RawRules -> String
getTitle name rules =
    case Dict.get name rules of
        Just rule ->
            Maybe.withDefault name rule.titre

        Nothing ->
            name


getUnit : RuleName -> RawRules -> Maybe String
getUnit name rules =
    Dict.get name rules
        |> Maybe.andThen .unite


mechanismToFloat : Mechanism -> Maybe Float
mechanismToFloat mechanism =
    case mechanism of
        Expr e ->
            NodeValue.toFloat e

        _ ->
            Nothing
