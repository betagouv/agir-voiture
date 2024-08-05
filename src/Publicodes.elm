module Publicodes exposing (..)

import Dict exposing (Dict)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), frenchLocale)
import Json.Decode as Decode exposing (Decoder, lazy, list, map, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type alias RuleName =
    String


type alias SplitedRuleName =
    List RuleName


type NodeValue
    = Str String
    | Number Float
    | Boolean Bool
    | Empty


exprDecoder : Decoder NodeValue
exprDecoder =
    Decode.oneOf
        [ Decode.map
            (\str ->
                case str of
                    "oui" ->
                        Boolean True

                    "non" ->
                        Boolean False

                    _ ->
                        Str str
            )
            Decode.string
        , Decode.map Number Decode.float
        , Decode.map Boolean Decode.bool
        , Decode.null Empty
        ]


nodeValueEncoder : NodeValue -> Encode.Value
nodeValueEncoder nodeValue =
    case nodeValue of
        Str str ->
            Encode.string (toConstantString str)

        Number num ->
            Encode.float num

        Boolean bool ->
            if bool then
                Encode.string "oui"

            else
                Encode.string "non"

        Empty ->
            Encode.null


nodeValueToString : NodeValue -> String
nodeValueToString nodeValue =
    case nodeValue of
        Str str ->
            str

        Number num ->
            format { frenchLocale | decimals = Exact 1 } num

        Boolean bool ->
            if bool then
                "oui"

            else
                "non"

        Empty ->
            ""


nodeValueToFloat : NodeValue -> Maybe Float
nodeValueToFloat nodeValue =
    case nodeValue of
        Number num ->
            Just num

        _ ->
            Nothing


type alias RawRules =
    Dict RuleName RawRule


type alias Situation =
    Dict RuleName NodeValue


situationDecoder : Decoder Situation
situationDecoder =
    Decode.dict exprDecoder


encodeSituation : Situation -> Encode.Value
encodeSituation situation =
    Encode.dict identity nodeValueEncoder situation



-- TODO: could be more precise


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
        |> required "avec" situationDecoder



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
        [ map Expr exprDecoder
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


rawRulesDecoder : Decoder RawRules
rawRulesDecoder =
    Decode.dict rawRuleDecoder


type alias Evaluation =
    { nodeValue : NodeValue
    , isApplicable : Bool
    }


evaluationDecoder : Decode.Decoder Evaluation
evaluationDecoder =
    Decode.succeed Evaluation
        |> required "nodeValue" exprDecoder
        |> required "isApplicable" Decode.bool



-- Helpers


{-| Publicodes enums needs to be single quoted

TODO: express constant strings in a more type-safe way

-}
toConstantString : String -> String
toConstantString str =
    "'" ++ str ++ "'"


split : RuleName -> SplitedRuleName
split =
    String.split " . "


join : SplitedRuleName -> RuleName
join =
    String.join " . "


namespace : RuleName -> RuleName
namespace ruleName =
    split ruleName
        |> List.head
        |> Maybe.withDefault ruleName


{-| Decode a rule name from a URL path. Elm implementation of `publicodes/utils.ts#decodeRuleName`
-}
decodeRuleName : String -> RuleName
decodeRuleName urlPath =
    urlPath
        |> String.replace "/" " . "
        |> String.replace "-" " "
        |> --NOTE: it's [\u{2011}] but when formatted it's became [‑] (which is different from [-])
           String.replace "‑" "-"
