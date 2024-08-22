module Core.Rules exposing (..)

{-| This module contains all the helper functions to manipulate the Publicodes rules of
the [`publicodes-voiture`](https://github.com/betagouv/publicodes-voiture) model.

It's not intended to be generic to all Publicodes models.

-}

import Dict exposing (Dict)
import List.Extra
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName, namespace, split)
import Regex



-- FIXME: all hardcoded values should be moved to the publicodes-voiture model
-- to be reused and type checked.


{-| The namespace of the rules that corresponds to all the combined
results in term of carbon emissions.
-}
resultNamespaces : List RuleName
resultNamespaces =
    [ "empreinte", "coût" ]


{-| The name of the rule that represents the total emission for the user car.
-}
userEmission : RuleName
userEmission =
    "empreinte . voiture"


{-| The name of the rule that represents the total cost for the user car.
-}
userCost : RuleName
userCost =
    "coût . voiture"


{-| Returns the user situation to show in the results.
-}
userContext : List RuleName
userContext =
    [ "voiture . gabarit"
    , "voiture . motorisation"
    , "voiture . thermique . carburant"
    , "voiture . thermique . consommation"
    , "usage . km annuels"
    ]


getNumValue : Dict RuleName Evaluation -> RuleName -> Maybe Float
getNumValue evaluations ruleName =
    evaluations
        |> Dict.get ruleName
        |> Maybe.andThen (\{ nodeValue } -> Just nodeValue)
        |> Maybe.andThen Publicodes.NodeValue.toFloat


getUserEmission : Dict RuleName Evaluation -> Maybe Float
getUserEmission evaluations =
    getNumValue evaluations userEmission


getUserCost : Dict RuleName Evaluation -> Maybe Float
getUserCost evaluations =
    getNumValue evaluations userCost


{-| Returns the user values for the emission and the cost.
-}
getUserValues :
    Dict RuleName Evaluation
    -> { userEmission : Maybe Float, userCost : Maybe Float }
getUserValues evaluations =
    { userEmission = getUserEmission evaluations, userCost = getUserCost evaluations }


getResultRules : RawRules -> List RuleName
getResultRules rules =
    rules
        |> Dict.keys
        |> List.filterMap
            (\name ->
                case split name of
                    namespace :: _ ->
                        if List.member namespace resultNamespaces then
                            Just name

                        else
                            Nothing

                    _ ->
                        Nothing
            )


getQuestions : RawRules -> List String -> Dict String (List RuleName)
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
                        namespace name
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


isInCategory : RuleName -> RuleName -> Bool
isInCategory category ruleName =
    split ruleName
        |> List.head
        |> Maybe.withDefault ""
        |> (\namespace -> namespace == category)


getStringFromSituation : NodeValue -> String
getStringFromSituation stringValue =
    let
        regex =
            Maybe.withDefault Regex.never (Regex.fromString "^'|'$")
    in
    stringValue
        |> Publicodes.NodeValue.toString
        |> Regex.replace regex (\_ -> "")


{-| Get the title of a `possibilite` value from the `contexte` and `optionVal`.

For now, it expects that the `optionVal` is a full rule name, or a relative
rule name from the `contexte`.

TODO: simply use the disambiguate function from the publicodes library.

-}
getOptionTitle :
    { rules : RawRules
    , namespace : Maybe RuleName
    , optionValue : RuleName
    }
    -> String
getOptionTitle props =
    case props.namespace of
        Nothing ->
            props.rules
                |> Dict.get props.optionValue
                |> Maybe.andThen .titre
                |> Maybe.withDefault props.optionValue

        Just contexte ->
            props.rules
                |> Dict.get (contexte ++ " . " ++ props.optionValue)
                |> Maybe.andThen .titre
                |> Maybe.withDefault
                    (getOptionTitle { props | namespace = Nothing })


{-| Get the string value of a item in a `possibilité` mechanism.

    getOptionValue "voiture . gabarit . moyenne" == "moyenne"

    getOptionValue "gabarit" == "gabarit"

-}
getOptionValue : RuleName -> String
getOptionValue val =
    split val
        |> List.Extra.last
        |> Maybe.withDefault val
