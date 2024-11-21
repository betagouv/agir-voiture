module Core.Rules exposing (..)

{-| This module contains all the helper functions to manipulate the Publicodes rules of
the [`publicodes-voiture`](https://github.com/betagouv/publicodes-voiture) model.

It's not intended to be generic to all Publicodes models.

-}

import Dict exposing (Dict)
import List.Extra
import Publicodes exposing (RawRules)
import Publicodes.NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName, namespace, split)
import Regex



-- FIXME: all hardcoded values should be moved to the publicodes-voiture model
-- to be reused and type checked.


{-| The name of the rule that represents the total carbon emissions for the user car.
-}
userEmissions : RuleName
userEmissions =
    "empreinte"


{-| The name of the rule that represents the total cost for the user car.
-}
userCost : RuleName
userCost =
    "coûts"


{-| Returns the user situation to show in the results.
TODO: resultContext?
-}
userContext : List RuleName
userContext =
    [ "voiture . gabarit"
    , "voiture . motorisation"
    , "voiture . thermique . carburant"
    , "voiture . thermique . consommation carburant"
    , "voiture . thermique . prix carburant"
    , "voiture . électrique . consommation électricité"
    , "voiture . prix d'achat"

    -- TODO: manage boolean,        "voiture . occasion"
    , "usage . km annuels"
    ]


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
