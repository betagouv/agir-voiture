module Core.Results.RuleValue exposing (RuleValue, decoderWith, title)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)


{-| Elm representation of the `RuleValue` type from @betagouv/publicodes-voiture.
-}
type alias RuleValue a =
    { value : a
    , unit : Maybe String
    , title : Maybe String
    , isEnumValue : Bool
    , isApplicable : Bool
    }


decoderWith : Decoder a -> Decoder (RuleValue a)
decoderWith valueDecoder =
    Decode.succeed RuleValue
        |> required "value" valueDecoder
        |> optional "unit" (Decode.maybe Decode.string) Nothing
        |> required "title" (Decode.maybe Decode.string)
        |> required "isEnumValue" Decode.bool
        |> required "isApplicable" Decode.bool


title : RuleValue String -> String
title ruleValue =
    Maybe.withDefault ruleValue.value ruleValue.title
