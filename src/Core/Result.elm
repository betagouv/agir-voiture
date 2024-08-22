module Core.Result exposing (..)

import Core.Rules as Rules
import Dict exposing (Dict)
import List.Extra
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.Helpers as Helpers
import Publicodes.NodeValue
import Publicodes.RuleName as RuleName exposing (RuleName, SplitedRuleName, split)


{-| A comparison item that represents a car with its cost and its carbon emissions.
-}
type ComputedResult
    = CurrentUserCar { cost : Float, emission : Float }
    | AlternativeCar ComputedResultInfos


{-| Fully resolved informations about a car that can be compared.
-}
type alias ComputedResultInfos =
    { title : String
    , motorisation : String
    , gabarit : String
    , carburant : Maybe String
    , cost : Float
    , emission : Float
    }


getMotorisationTitle : String -> RawRules -> String
getMotorisationTitle motorisation rules =
    Helpers.getTitle
        (RuleName.join [ "voiture", "motorisation", motorisation ])
        rules


getGabaritTitle : String -> RawRules -> String
getGabaritTitle gabarit rules =
    Helpers.getTitle
        (RuleName.join [ "voiture", "gabarit", gabarit ])
        rules


getCarburantTitle : String -> RawRules -> String
getCarburantTitle carburant rules =
    Helpers.getTitle
        (RuleName.join [ "voiture", "thermique", "carburant", carburant ])
        rules


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


getNumValue : Dict RuleName Evaluation -> RuleName -> Maybe Float
getNumValue evaluations ruleName =
    evaluations
        |> Dict.get ruleName
        |> Maybe.andThen (\{ nodeValue } -> Just nodeValue)
        |> Maybe.andThen Publicodes.NodeValue.toFloat


getUserEmission : Dict RuleName Evaluation -> Maybe Float
getUserEmission evaluations =
    getNumValue evaluations Rules.userEmission


getUserCost : Dict RuleName Evaluation -> Maybe Float
getUserCost evaluations =
    getNumValue evaluations Rules.userCost


{-| Returns the user values for the emission and the cost.
-}
getUserValues :
    Dict RuleName Evaluation
    -> { userEmission : Maybe Float, userCost : Maybe Float }
getUserValues evaluations =
    { userEmission = getUserEmission evaluations, userCost = getUserCost evaluations }


getCostValueOf : SplitedRuleName -> Dict RuleName Evaluation -> Maybe Float
getCostValueOf name evaluations =
    ("coût" :: name)
        |> RuleName.join
        |> getNumValue evaluations


getEmissionValueOf : SplitedRuleName -> Dict RuleName Evaluation -> Maybe Float
getEmissionValueOf name evaluations =
    ("empreinte" :: name)
        |> RuleName.join
        |> getNumValue evaluations


getResultRules : RawRules -> List RuleName
getResultRules rules =
    rules
        |> Dict.keys
        |> List.filterMap
            (\name ->
                case split name of
                    namespace :: _ ->
                        if List.member namespace Rules.resultNamespaces then
                            Just name

                        else
                            Nothing

                    _ ->
                        Nothing
            )


getComputedResults :
    { resultRules : List RuleName
    , evaluations : Dict RuleName Evaluation
    , rules : RawRules
    }
    -> List ComputedResult
getComputedResults props =
    props.resultRules
        |> List.filterMap
            (\name ->
                case RuleName.split name of
                    namespace :: rest ->
                        if List.member namespace Rules.resultNamespaces then
                            case
                                ( getCostValueOf rest props.evaluations
                                , getEmissionValueOf rest props.evaluations
                                )
                            of
                                ( Just cost, Just emission ) ->
                                    case rest of
                                        motorisation :: gabarit :: maybeCarburant ->
                                            Just <|
                                                AlternativeCar
                                                    { title = Helpers.getTitle name props.rules
                                                    , motorisation =
                                                        getMotorisationTitle motorisation props.rules
                                                    , gabarit =
                                                        getGabaritTitle gabarit props.rules
                                                    , carburant =
                                                        case maybeCarburant of
                                                            carburant :: [] ->
                                                                Just (getCarburantTitle carburant props.rules)

                                                            _ ->
                                                                Nothing
                                                    , cost = cost
                                                    , emission = emission
                                                    }

                                        [ "voiture" ] ->
                                            Just <|
                                                CurrentUserCar
                                                    { cost = cost
                                                    , emission = emission
                                                    }

                                        _ ->
                                            Nothing

                                _ ->
                                    Nothing

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.Extra.unique
