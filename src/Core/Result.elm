module Core.Result exposing (..)

import Core.Rules as Rules
import Dict exposing (Dict)
import List.Extra
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.Helpers as Helpers
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName as RuleName exposing (RuleName, SplitedRuleName, split)


{-| A comparison item that represents a car with its cost and its carbon emissions.
-}
type ComputedResult
    = CurrentUserCar
        { cost : Float
        , emission : Float
        , gabarit : String
        , motorisation : String
        }
    | AlternativeCar ComputedResultInfos


{-| Fully resolved informations about a car that can be compared.
-}
type alias ComputedResultInfos =
    { title : String
    , carburant : Maybe String
    , cost : Float
    , emission : Float
    , gabarit : String
    , motorisation : String
    }


getMotorisationTitle : String -> RawRules -> String
getMotorisationTitle motorisation =
    Helpers.getTitle
        (RuleName.join [ "voiture", "motorisation", motorisation ])


getGabaritTitle : String -> RawRules -> String
getGabaritTitle gabarit =
    Helpers.getTitle
        (RuleName.join [ "voiture", "gabarit", gabarit ])


getCarburantTitle : String -> RawRules -> String
getCarburantTitle carburant =
    Helpers.getTitle
        (RuleName.join [ "voiture", "thermique", "carburant", carburant ])


compareWith :
    ({ cost : Float, emission : Float, gabarit : String, motorisation : String }
     -> { cost : Float, emission : Float, gabarit : String, motorisation : String }
     -> Order
    )
    -> ComputedResult
    -> ComputedResult
    -> Order
compareWith compare a b =
    let
        -- NOTE: Only needed because of a bug in the compiler that doesn't allow to
        -- resolve ComputedResultInfos into { a | cost : Float, emission : Float, ... }.
        map { cost, emission, gabarit, motorisation } =
            { cost = cost, emission = emission, gabarit = gabarit, motorisation = motorisation }
    in
    case ( a, b ) of
        ( AlternativeCar carA, AlternativeCar carB ) ->
            compare (map carA) (map carB)

        ( CurrentUserCar user, AlternativeCar car ) ->
            compare user (map car)

        ( AlternativeCar car, CurrentUserCar user ) ->
            compare (map car) user

        ( CurrentUserCar userA, CurrentUserCar userB ) ->
            -- Should not happen
            compare userA userB


getNumValue : RuleName -> Dict RuleName Evaluation -> Maybe Float
getNumValue ruleName evaluations =
    evaluations
        |> Dict.get ruleName
        |> Maybe.map .nodeValue
        |> Maybe.andThen NodeValue.toFloat


getUserEmission : Dict RuleName Evaluation -> Maybe Float
getUserEmission =
    getNumValue Rules.userEmission


getUserCost : Dict RuleName Evaluation -> Maybe Float
getUserCost =
    getNumValue Rules.userCost


{-| Returns the user values for the emission and the cost.
-}
getUserValues :
    Dict RuleName Evaluation
    -> { userEmission : Maybe Float, userCost : Maybe Float }
getUserValues evaluations =
    { userEmission = getUserEmission evaluations, userCost = getUserCost evaluations }


getCostValueOf : SplitedRuleName -> Dict RuleName Evaluation -> Maybe Float
getCostValueOf name =
    getNumValue (RuleName.join ("coût" :: name))


getEmissionValueOf : SplitedRuleName -> Dict RuleName Evaluation -> Maybe Float
getEmissionValueOf name =
    getNumValue (RuleName.join ("empreinte" :: name))


getStringValue : RuleName -> Dict RuleName Evaluation -> Maybe String
getStringValue name evaluations =
    evaluations
        |> Dict.get name
        |> Maybe.map .nodeValue
        |> Maybe.map NodeValue.toString


getBooleanValue : RuleName -> Dict RuleName Evaluation -> Maybe Bool
getBooleanValue name evaluations =
    evaluations
        |> Dict.get name
        |> Maybe.map .nodeValue
        |> Maybe.andThen
            (\value ->
                case value of
                    NodeValue.Boolean b ->
                        Just b

                    _ ->
                        Nothing
            )


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
                                            let
                                                userGabarit =
                                                    props.evaluations
                                                        |> getStringValue Rules.userGabarit
                                                        |> Maybe.map
                                                            (\gabarit ->
                                                                getGabaritTitle gabarit props.rules
                                                            )
                                                        |> Maybe.withDefault ""

                                                userMotorisation =
                                                    props.evaluations
                                                        |> getStringValue Rules.userMotorisation
                                                        |> Maybe.map
                                                            (\motorisation ->
                                                                getMotorisationTitle motorisation props.rules
                                                            )
                                                        |> Maybe.withDefault ""
                                            in
                                            Just <|
                                                CurrentUserCar
                                                    { cost = cost
                                                    , emission = emission
                                                    , gabarit = userGabarit
                                                    , motorisation = userMotorisation
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
