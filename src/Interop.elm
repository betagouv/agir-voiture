port module Interop exposing (onReactLinkClicked)

{-| -}


{-| A link was clicked on the custom [RulePage] component.

    The link is a string that represents the URL of the page to navigate to.

-}
port onReactLinkClicked : (String -> msg) -> Sub msg
