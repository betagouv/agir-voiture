module Core.Result exposing (..)

import Dict exposing (Dict)
import Helpers
import Publicodes.Publicodes as P


{-| A comparison item that represents a car with its cost and its carbon emissions.
-}
type ComputedResult
    = CurrentUserCar { cost : Float, emission : Float }
    | AlternativeCar ComputedResultInfos


{-| Fully resolved informations about a car that can be compared.
-}
type alias ComputedResultInfos =
    { motorisation : String
    , gabarit : String
    , carburant : String
    , cost : Float
    , emission : Float
    }


getMotorisationTitle : P.RawRules -> String -> String
getMotorisationTitle rules motorisation =
    Helpers.getTitle rules (P.join [ "voiture", "motorisation", motorisation ])


getGabaritTitle : P.RawRules -> String -> String
getGabaritTitle rules gabarit =
    Helpers.getTitle rules (P.join [ "voiture", "gabarit", gabarit ])


getCarburantTitle : P.RawRules -> String -> String
getCarburantTitle rules carburant =
    Helpers.getTitle rules (P.join [ "voiture", "thermique", "carburant", carburant ])


compareWith :
    ({ cost : Float, emission : Float } -> { cost : Float, emission : Float } -> Order)
    -> ComputedResult
    -> ComputedResult
    -> Order
compareWith compare a b =
    let
        -- NOTE: Only needed because of a bug in the compiler that doesn't allow to
        -- resolve ComputedResultInfos into { a | cost : Float, emission : Float }.
        toCostEmission { cost, emission } =
            { cost = cost, emission = emission }
    in
    case ( a, b ) of
        ( AlternativeCar carA, AlternativeCar carB ) ->
            compare (toCostEmission carA) (toCostEmission carB)

        ( CurrentUserCar user, AlternativeCar car ) ->
            compare user (toCostEmission car)

        ( AlternativeCar car, CurrentUserCar user ) ->
            compare (toCostEmission car) user

        ( CurrentUserCar userA, CurrentUserCar userB ) ->
            -- Should not happen
            compare userA userB



--  TODO: should be defined in ui.yaml


{-| The namespaces of the rules that corresponds to all the combined
results in term of carbon emissions.
-}
resultNamespaces : List P.RuleName
resultNamespaces =
    [ "empreinte", "coût" ]


{-| The name of the rule that represents the total emission for the user car.
-}
userEmission : P.RuleName
userEmission =
    "empreinte . voiture"


{-| The name of the rule that represents the total cost for the user car.
-}
userCost : P.RuleName
userCost =
    "coût . voiture"


getNumValue : Dict P.RuleName P.Evaluation -> P.RuleName -> Maybe Float
getNumValue evaluations ruleName =
    evaluations
        |> Dict.get ruleName
        |> Maybe.andThen (\{ nodeValue } -> Just nodeValue)
        |> Maybe.andThen P.nodeValueToFloat


getUserEmission : Dict P.RuleName P.Evaluation -> Maybe Float
getUserEmission evaluations =
    getNumValue evaluations userEmission


getUserCost : Dict P.RuleName P.Evaluation -> Maybe Float
getUserCost evaluations =
    getNumValue evaluations userCost


{-| Returns the user values for the emission and the cost.
-}
getUserValues :
    Dict P.RuleName P.Evaluation
    -> { maybeUserEmission : Maybe Float, maybeUserCost : Maybe Float }
getUserValues evaluations =
    { maybeUserEmission = getUserEmission evaluations, maybeUserCost = getUserCost evaluations }


getCostValueOf : Dict P.RuleName P.Evaluation -> P.SplitedRuleName -> Maybe Float
getCostValueOf evaluations name =
    "coût"
        :: name
        |> P.join
        |> getNumValue evaluations


getEmissionValueOf : Dict P.RuleName P.Evaluation -> P.SplitedRuleName -> Maybe Float
getEmissionValueOf evaluations name =
    "empreinte"
        :: name
        |> P.join
        |> getNumValue evaluations


getRules : P.RawRules -> List P.RuleName
getRules rules =
    rules
        |> Dict.keys
        |> List.filterMap
            (\name ->
                case P.split name of
                    namespace :: _ ->
                        if List.member namespace resultNamespaces then
                            Just name

                        else
                            Nothing

                    _ ->
                        Nothing
            )
