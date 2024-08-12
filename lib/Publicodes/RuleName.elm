module Publicodes.RuleName exposing
    ( RuleName
    , SplitedRuleName
    , decodeFromPath
    , join
    , namespace
    , split
    )


type alias RuleName =
    String


type alias SplitedRuleName =
    List String


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


{-| Decode a rule name from a URL path.

Elm implementation of `publicodes/utils.ts#decodeRuleName`

-}
decodeFromPath : String -> RuleName
decodeFromPath urlPath =
    urlPath
        |> String.replace "/" " . "
        |> String.replace "-" " "
        |> --NOTE: it's [\u{2011}] but when formatted it's became [‑] (which is different from [-])
           String.replace "‑" "-"
