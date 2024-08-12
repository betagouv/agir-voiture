module Publicodes.NodeValue exposing
    ( NodeValue
    , decoder
    , encode
    , toFloat
    , toString
    )

import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), frenchLocale)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type NodeValue
    = Str String
    | Number Float
    | Boolean Bool
    | Empty


decoder : Decoder NodeValue
decoder =
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


encode : NodeValue -> Encode.Value
encode nodeValue =
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


toString : NodeValue -> String
toString nodeValue =
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


toFloat : NodeValue -> Maybe Float
toFloat nodeValue =
    case nodeValue of
        Number num ->
            Just num

        _ ->
            Nothing


{-| Publicodes enums needs to be single quoted

TODO: express constant strings in a more type-safe way

-}
toConstantString : String -> String
toConstantString str =
    "'" ++ str ++ "'"
