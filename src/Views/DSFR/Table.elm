module Views.DSFR.Table exposing (..)

import Accessibility exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (viewMaybe)


type alias Config msg =
    { caption : Maybe String
    , headers : List String
    , rows : List (List (Html msg))
    }


view : Config msg -> Html msg
view config =
    div [ class "fr-table--sm fr-table fr-table--bordered" ]
        [ div [ class "fr-table__wrapper" ]
            [ div [ class "fr-table__container" ]
                [ div [ class "fr-table__content" ]
                    [ table [ id "comparison-table" ]
                        [ caption [ class "fr-h6" ]
                            [ viewMaybe text config.caption
                            ]
                        , thead
                            []
                            [ tr []
                                (config.headers
                                    |> List.map (\header -> th [ scope "col" ] [ text header ])
                                )
                            ]
                        , tbody []
                            (config.rows
                                |> List.indexedMap
                                    (\i row ->
                                        let
                                            idx =
                                                String.fromInt i
                                        in
                                        tr [ id ("table-sm-row-key-" ++ idx), attribute "data-row-key" idx ]
                                            (row
                                                |> List.map (\cell -> td [] [ cell ])
                                            )
                                    )
                            )
                        ]
                    ]
                ]
            ]
        ]
