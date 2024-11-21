module Core.Results exposing (..)

import Core.Evaluation exposing (Evaluation)
import Core.Results.CarInfos as CarInfos exposing (CarInfos)
import Core.Results.TargetInfos as TargetInfos exposing (TargetInfos)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Publicodes exposing (RawRules)
import Publicodes.Helpers as Helpers
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName as RuleName exposing (RuleName, SplitedRuleName)


type alias Results =
    { user : CarInfos
    , -- TODO: must be refactored with a more generic type when other
      -- alternatives will be introduced
      alternatives : List CarInfos
    , target : TargetInfos
    }


decoder : Decode.Decoder Results
decoder =
    Decode.succeed Results
        |> required "user" CarInfos.decoder
        |> required "alternatives" (Decode.list CarInfos.decoder)
        |> required "target" TargetInfos.decoder


type ResultType
    = Cost
    | Emissions


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
