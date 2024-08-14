module Publicodes exposing
    ( Evaluation
    , Mecanism(..)
    , RawRule
    , RawRules
    , decodeRawRules
    , evaluationDecoder
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, lazy, list, map, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation as Situation exposing (Situation)


type alias Clause =
    { si : Maybe Mecanism
    , alors : Maybe Mecanism
    , sinon : Maybe Mecanism
    }


clauseDecoder : Decoder Clause
clauseDecoder =
    Decode.succeed Clause
        |> optional "si" (nullable mecanismDecoder) Nothing
        |> optional "alors" (nullable mecanismDecoder) Nothing
        |> optional "sinon" (nullable mecanismDecoder) Nothing


type alias PossibiliteNode =
    { choix_obligatoire : Maybe String
    , possibilites : List String
    }


possibiliteNodeDecoder : Decoder PossibiliteNode
possibiliteNodeDecoder =
    Decode.succeed PossibiliteNode
        |> optional "choix obligatoire" (nullable string) Nothing
        |> required "possibilités" (list string)


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
type alias ChainedMecanisms =
    { valeur : Maybe Mecanism
    , somme : Maybe (List String)
    , moyenne : Maybe (List String)
    , variations : Maybe (List Clause)
    , une_possibilite : Maybe PossibiliteNode
    , toutes_ces_conditions : Maybe (List Clause)
    , une_de_ces_conditions : Maybe (List Clause)
    , recalcul : Maybe RecalculNode
    , est_defini : Maybe String
    }


type Mecanism
    = Expr NodeValue
    | ChainedMecanism ChainedMecanisms


mecanismDecoder : Decoder Mecanism
mecanismDecoder =
    Decode.oneOf
        [ map Expr NodeValue.decoder
        , map ChainedMecanism chainedMecanismsDecoder
        ]


chainedMecanismsDecoder : Decoder ChainedMecanisms
chainedMecanismsDecoder =
    Decode.succeed ChainedMecanisms
        |> optional "valeur" (nullable (lazy (\_ -> mecanismDecoder))) Nothing
        |> optional "somme" (nullable (list string)) Nothing
        |> optional "moyenne" (nullable (list string)) Nothing
        |> optional "variations" (nullable (list (lazy (\_ -> clauseDecoder)))) Nothing
        |> optional "une possibilité" (nullable possibiliteNodeDecoder) Nothing
        |> optional "toutes ces conditions" (nullable (list (lazy (\_ -> clauseDecoder)))) Nothing
        |> optional "une de ces conditions" (nullable (list (lazy (\_ -> clauseDecoder)))) Nothing
        |> optional "recalcul" (nullable recalculNodeDecoder) Nothing
        |> optional "est défini" (nullable string) Nothing


{-| TODO: correctly define RawRule as ChainedMecanism with a few extra fields
-}
type alias RawRule =
    { question : Maybe String
    , description : Maybe String
    , resume : Maybe String
    , unite : Maybe String
    , par_defaut : Maybe Mecanism
    , formule : Maybe Mecanism
    , valeur : Maybe Mecanism
    , titre : Maybe String
    , note : Maybe String
    , plancher : Maybe Mecanism
    }


rawRuleDecoder : Decoder RawRule
rawRuleDecoder =
    Decode.succeed RawRule
        |> optional "question" (nullable string) Nothing
        |> optional "description" (nullable string) Nothing
        |> optional "résumé" (nullable string) Nothing
        |> optional "unité" (nullable string) Nothing
        |> optional "par défaut" (nullable mecanismDecoder) Nothing
        |> optional "formule" (nullable mecanismDecoder) Nothing
        |> optional "valeur" (nullable mecanismDecoder) Nothing
        |> optional "titre" (nullable string) Nothing
        |> optional "note" (nullable string) Nothing
        |> optional "plancher" (nullable mecanismDecoder) Nothing


type alias RawRules =
    Dict RuleName RawRule


decodeRawRules : Decoder RawRules
decodeRawRules =
    Decode.dict rawRuleDecoder


type alias Evaluation =
    { nodeValue : NodeValue
    , isApplicable : Bool
    }


evaluationDecoder : Decode.Decoder Evaluation
evaluationDecoder =
    Decode.succeed Evaluation
        |> required "nodeValue" NodeValue.decoder
        |> required "isApplicable" Decode.bool
