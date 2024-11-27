module Core.Format exposing (floatToFrenchLocale, withPrecision)

{-| This module contains all the helper functions to format numbers in the
application.
-}

import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals, base, frenchLocale)


floatToFrenchLocale : Decimals -> Float -> String
floatToFrenchLocale decimals =
    format { frenchLocale | decimals = decimals }


withPrecision : Decimals -> Float -> String
withPrecision decimals =
    format { base | decimals = decimals }
