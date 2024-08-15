module Core.Format exposing (..)

{-| This module contains all the helper functions to format numbers in the
application.
-}

import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), base, frenchLocale)


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
carbonResult : Float -> ( String, String )
carbonResult number =
    let
        formatWithPrecision convertedValue =
            let
                precision =
                    if convertedValue < 1000 then
                        Max 1

                    else
                        Max 0
            in
            floatToFrenchLocale precision convertedValue
    in
    if number < 10000 then
        ( formatWithPrecision number, "kgCO2e" )

    else
        ( formatWithPrecision (number / 1000), "tCO2e" )


percent : Float -> String
percent pct =
    floatToFrenchLocale (Max 1) pct ++ " %"


floatToFrenchLocale : Decimals -> Float -> String
floatToFrenchLocale decimals =
    format { frenchLocale | decimals = decimals }


withPrecision : Decimals -> Float -> String
withPrecision decimals =
    format { base | decimals = decimals }
