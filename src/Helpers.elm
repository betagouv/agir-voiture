module Helpers exposing (..)

import Dict exposing (Dict)
import File exposing (File)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), frenchLocale)
import Json.Decode as Decode exposing (Decoder)
import Publicodes.Publicodes as P
import Regex
import Task
import Time



-- RESULT RULE HELPERS
--  TODO: should be defined in ui.yaml


{-| The namespace of the rules that corresponds to all the combined
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
    -> { userEmission : Maybe Float, userCost : Maybe Float }
getUserValues evaluations =
    { userEmission = getUserEmission evaluations, userCost = getUserCost evaluations }


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


getResultRules : P.RawRules -> List P.RuleName
getResultRules rules =
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



-- PUBLICODES HELPERS


getQuestions : P.RawRules -> List String -> Dict String (List P.RuleName)
getQuestions rules categories =
    Dict.toList rules
        |> List.filterMap
            (\( name, rule ) ->
                Maybe.map (\_ -> name) rule.question
            )
        |> List.foldl
            (\name dict ->
                let
                    category =
                        P.namespace name
                in
                if List.member category categories then
                    Dict.update category
                        (\maybeList ->
                            case maybeList of
                                Just list ->
                                    Just (name :: list)

                                Nothing ->
                                    Just [ name ]
                        )
                        dict

                else
                    dict
            )
            Dict.empty


isInCategory : P.RuleName -> P.RuleName -> Bool
isInCategory category ruleName =
    P.split ruleName
        |> List.head
        |> Maybe.withDefault ""
        |> (\namespace -> namespace == category)


{-| Get the title of a rule from its name.
If the rule doesn't have a title, the name is returned.
-}
getTitle : P.RawRules -> P.RuleName -> String
getTitle rules name =
    case Dict.get name rules of
        Just rule ->
            Maybe.withDefault name rule.titre

        Nothing ->
            name


getUnit : P.RawRules -> P.RuleName -> Maybe String
getUnit rules name =
    Dict.get name rules
        |> Maybe.andThen .unite


getStringFromSituation : P.NodeValue -> String
getStringFromSituation stringValue =
    let
        regex =
            Maybe.withDefault Regex.never (Regex.fromString "^'|'$")
    in
    stringValue
        |> P.nodeValueToString
        |> Regex.replace regex (\_ -> "")


{-| TODO: should find a way to use the [disambiguateReference] function from
[publicodes]
-}
getOptionTitle : P.RawRules -> P.RuleName -> P.RuleName -> String
getOptionTitle rules contexte optionVal =
    rules
        |> Dict.get (contexte ++ " . " ++ optionVal)
        |> Maybe.andThen (\r -> r.titre)
        |> Maybe.withDefault optionVal



-- FORMATTING HELPERS


{-| Format a number to a "displayable" pair (formatedValue, formatedUnit).

The number **is expected to be in kgCO2e**.

    -- Format in french locale
    formatCarbonResult (Just 1234) == ( "1 234", "kgCO2e" )

    -- Round to 1 decimal when < 1000 kgCO2e
    formatCarbonResult (Just 123.45) == ( "123,5", "kgCO2e" )

    -- Round to 0 decimal when >= 1000 kgCO2e
    formatCarbonResult (Just 1234.56) == ( "1 235", "kgCO2e" )

    -- Convert to tCO2e and round to 1 decimal when > 10000 kgCO2e
    formatCarbonResult (Just 34567) == ( "34,6", "tCO2e" )

    -- Convert to tCO2e and round to 0 decimal when >= 1000000 kgCO2e
    formatCarbonResult (Just 340000.56) == ( "340", "tCO2e" )

-}
formatCarbonResult : Float -> ( String, String )
formatCarbonResult number =
    let
        formatWithPrecision convertedValue =
            let
                precision =
                    if convertedValue < 1000 then
                        Max 1

                    else
                        Max 0
            in
            formatFloatToFrenchLocale precision convertedValue
    in
    if number < 10000 then
        ( formatWithPrecision number, "kgCO2e" )

    else
        ( formatWithPrecision (number / 1000), "tCO2e" )


formatPercent : Float -> String
formatPercent pct =
    formatFloatToFrenchLocale (Max 1) pct ++ " %"


formatFloatToFrenchLocale : Decimals -> Float -> String
formatFloatToFrenchLocale decimals =
    format { frenchLocale | decimals = decimals }



-- JSON DECODERS


filesDecoder : Decoder (List File)
filesDecoder =
    Decode.at [ "target", "files" ] (Decode.list File.decoder)



-- LIST HELPERS


{-| Drops elements from [list] until the next element satisfies [predicate].

@returns [] if no element satisfies the [predicate].
@returns [list] if the first element satisfies the [predicate].

    dropUntilNext ((==) 3) [ 1, 2, 3, 4, 5 ] == [ 2, 3, 4, 5 ]

    dropUntilNext ((==) 3) [ 1, 2, 3 ] == [ 2, 3 ]

    dropUntilNext ((==) 3) [ 1, 2 ] == []

    dropUntilNext ((==) 3) [ 3, 4, 5 ] == [ 3, 4, 5 ]

-}
dropUntilNext : (a -> Bool) -> List a -> List a
dropUntilNext predicate list =
    let
        go l =
            case l of
                _ :: x :: xs ->
                    if predicate x then
                        l

                    else
                        go (x :: xs)

                _ ->
                    []
    in
    case list of
        x :: _ ->
            if predicate x then
                list

            else
                go list

        _ ->
            []



-- CMD HELPERS


performCmdNow : msg -> Cmd msg
performCmdNow msg =
    Task.perform (\_ -> msg) Time.now
