module Core.Results.RuleValue exposing (RuleValue, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)


{-| Elm representation of the `RuleValue` type from @betagouv/publicodes-voiture.
-}
type alias RuleValue =
    { value : NodeValue
    , unit : Maybe String
    , title : Maybe String
    , isEnumValue : Bool
    , isApplicable : Bool
    }


decoder : Decoder RuleValue
decoder =
    Decode.succeed RuleValue
        |> required "value" NodeValue.decoder
        |> required "unit" (Decode.maybe Decode.string)
        |> required "title" (Decode.maybe Decode.string)
        |> required "isEnumValue" Decode.bool
        |> required "isApplicable" Decode.bool
