module Helper exposing (..)

{-| -}

import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Markdown


{-| Drops elements from [list] until the next element satisfies [predicate].

@returns [] if no element satisfies the [predicate].
@returns [list] if the first element satisfies the [predicate].

    dropUntilNext ((==) 3) [ 1, 2, 3, 4, 5 ] == [ 2, 3, 4, 5 ]

    dropUntilNext ((==) 3) [ 1, 2, 3 ] == [ 2, 3 ]

    dropUntilNext ((==) 3) [ 1, 2 ] == []

    dropUntilNext ((==) 3) [ 3, 4, 5 ] == [ 3, 4, 5 ]

-}
dropUntilNext : (a -> Bool) -> List a -> List a
dropUntilNext predicate list =
    let
        go l =
            case l of
                _ :: x :: xs ->
                    if predicate x then
                        l

                    else
                        go (x :: xs)

                _ ->
                    []
    in
    case list of
        x :: _ ->
            if predicate x then
                list

            else
                go list

        _ ->
            []


viewMarkdown : String -> Html msg
viewMarkdown markdown =
    div [ class "markdown" ] (Markdown.toHtml Nothing markdown)
