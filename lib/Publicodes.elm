module Publicodes exposing
    ( ChainedMechanisms
    , Clause
    , Mechanism(..)
    , RawRule
    , RawRules
    , RecalculNode
    , decodeRawRules
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, lazy, list, map, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation as Situation exposing (Situation)


type alias Clause =
    { si : Maybe Mechanism
    , alors : Maybe Mechanism
    , sinon : Maybe Mechanism
    }


clauseDecoder : Decoder Clause
clauseDecoder =
    Decode.succeed Clause
        |> optional "si" (nullable mechanismDecoder) Nothing
        |> optional "alors" (nullable mechanismDecoder) Nothing
        |> optional "sinon" (nullable mechanismDecoder) Nothing


type alias RecalculNode =
    { regle : RuleName
    , avec : Situation
    }


recalculNodeDecoder : Decoder RecalculNode
recalculNodeDecoder =
    Decode.succeed RecalculNode
        |> required "règle" string
        |> required "avec" Situation.decoder



-- type Mecanism
--     = Expr NodeValue
--     | Somme (List String)
--     | Moyenne (List String)
--     | Variations (List Clause)
--     | UnePossibilite PossibiliteNode
--     | ToutesCesConditions (List Clause)
--     | UneDeCesConditions (List Clause)
--     | Recalcul RecalculNode
--     | EstDefini String
--
--
-- mecanismDecoder : Decoder Mecanism
-- mecanismDecoder =
--     Decode.oneOf
--         [ map Expr nodeValueDecoder
--         , map Somme (field "somme" (list string))
--         , map Moyenne (field "moyenne" (list string))
--         , map Variations (field "variations" (list (lazy (\_ -> clauseDecoder))))
--         , map UnePossibilite (field "une possibilité" possibiliteNodeDecoder)
--         , map ToutesCesConditions (field "toutes ces conditions" (list (lazy (\_ -> clauseDecoder))))
--         , map UneDeCesConditions (field "une de ces conditions" (list (lazy (\_ -> clauseDecoder))))
--         , map Recalcul (field "recalcul" recalculNodeDecoder)
--         , map EstDefini (field "est défini" string)
--         ]
--


{-| TODO: could be a cleaner way to do this?
-}
type alias ChainedMechanisms =
    { valeur : Maybe Mechanism
    , somme : Maybe (List String)
    , moyenne : Maybe (List String)
    , variations : Maybe (List Clause)
    , toutes_ces_conditions : Maybe (List Clause)
    , une_de_ces_conditions : Maybe (List Clause)
    , recalcul : Maybe RecalculNode
    , est_defini : Maybe String
    }


type Mechanism
    = Expr NodeValue
    | ChainedMechanism ChainedMechanisms


mechanismDecoder : Decoder Mechanism
mechanismDecoder =
    Decode.oneOf
        [ map Expr NodeValue.decoder
        , map ChainedMechanism chainedMechanismsDecoder
        ]


chainedMechanismsDecoder : Decoder ChainedMechanisms
chainedMechanismsDecoder =
    Decode.succeed ChainedMechanisms
        |> optional "valeur" (nullable (lazy (\_ -> mechanismDecoder))) Nothing
        |> optional "somme" (nullable (list string)) Nothing
        |> optional "moyenne" (nullable (list string)) Nothing
        |> optional "variations" (nullable (list (lazy (\_ -> clauseDecoder)))) Nothing
        |> optional "toutes ces conditions" (nullable (list (lazy (\_ -> clauseDecoder)))) Nothing
        |> optional "une de ces conditions" (nullable (list (lazy (\_ -> clauseDecoder)))) Nothing
        |> optional "recalcul" (nullable recalculNodeDecoder) Nothing
        |> optional "est défini" (nullable string) Nothing


{-| TODO: correctly define RawRule as ChainedMechanism with a few extra fields
-}
type alias RawRule =
    { question : Maybe String
    , description : Maybe String
    , resume : Maybe String
    , unite : Maybe String
    , par_defaut : Maybe Mechanism
    , formule : Maybe Mechanism
    , valeur : Maybe Mechanism
    , titre : Maybe String
    , note : Maybe String
    , plancher : Maybe Mechanism
    , plafond : Maybe Mechanism
    , une_possibilite : Maybe (List String)
    }


rawRuleDecoder : Decoder RawRule
rawRuleDecoder =
    Decode.succeed RawRule
        |> optional "question" (nullable string) Nothing
        |> optional "description" (nullable string) Nothing
        |> optional "résumé" (nullable string) Nothing
        |> optional "unité" (nullable string) Nothing
        |> optional "par défaut" (nullable mechanismDecoder) Nothing
        |> optional "formule" (nullable mechanismDecoder) Nothing
        |> optional "valeur" (nullable mechanismDecoder) Nothing
        |> optional "titre" (nullable string) Nothing
        |> optional "note" (nullable string) Nothing
        |> optional "plancher" (nullable mechanismDecoder) Nothing
        |> optional "plafond" (nullable mechanismDecoder) Nothing
        |> optional "une possibilité" (nullable (list string)) Nothing


type alias RawRules =
    Dict RuleName RawRule


decodeRawRules : Decoder RawRules
decodeRawRules =
    Decode.dict rawRuleDecoder
