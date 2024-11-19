module Core.Results exposing (..)

import Core.Evaluation exposing (Evaluation)
import Core.Results.CarInfos as CarInfos exposing (CarInfos)
import Core.Rules as Rules
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import List.Extra
import Publicodes exposing (RawRules)
import Publicodes.Helpers as Helpers
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName as RuleName exposing (RuleName, SplitedRuleName, split)


type alias Results =
    { user : CarInfos

    -- , alternatives : List CarInfos
    }


decoder : Decode.Decoder Results
decoder =
    Decode.succeed Results
        |> required "user" CarInfos.decoder


{-| TODO: refactor with this
-}
type ResultType
    = Cost
    | Emission


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
        |> Maybe.map .value
        |> Maybe.andThen NodeValue.toFloat


getCostValueOf : SplitedRuleName -> Dict RuleName Evaluation -> Maybe Float
getCostValueOf name =
    getNumValue (RuleName.join ("coûts" :: name))


getEmissionValueOf : SplitedRuleName -> Dict RuleName Evaluation -> Maybe Float
getEmissionValueOf name =
    getNumValue (RuleName.join ("empreinte" :: name))


getStringValue : RuleName -> Dict RuleName Evaluation -> Maybe String
getStringValue name evaluations =
    evaluations
        |> Dict.get name
        |> Maybe.map .value
        |> Maybe.map NodeValue.toString


getBooleanValue : RuleName -> Dict RuleName Evaluation -> Maybe Bool
getBooleanValue name evaluations =
    evaluations
        |> Dict.get name
        |> Maybe.map .value
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
