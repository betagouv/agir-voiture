module Components.ComparisonTable exposing (view)

import Components.DSFR.Table
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes.Publicodes as P


view :
    { rawRules : P.RawRules
    , rulesToCompare : List ( P.SplitedRuleName, { cost : Float, emission : Float } )
    , userCost : Float
    , userEmission : Float
    }
    -> Html msg
view { rawRules, rulesToCompare, userCost, userEmission } =
    let
        getTitle =
            H.getTitle rawRules

        rows =
            rulesToCompare
                |> List.sortWith
                    (\( _, a ) ( _, b ) ->
                        -- Compare on emission first
                        -- TODO: add a way to choose the comparison
                        if a.emission == b.emission then
                            Basics.compare b.cost a.cost

                        else
                            Basics.compare a.emission b.emission
                    )
                |> List.map
                    (\( name, { cost, emission } ) ->
                        case name of
                            motorisation :: gabarit :: rest ->
                                [ text <| getTitle <| P.join [ "voiture", "motorisation", motorisation ]
                                , text <| getTitle <| P.join [ "voiture", "gabarit", gabarit ]
                                , case rest of
                                    carburant :: [] ->
                                        text <| getTitle <| P.join <| [ "voiture", "thermique", "carburant", carburant ]

                                    _ ->
                                        text "Électricité"
                                , viewValuePlusDiff emission userEmission "kg"
                                , viewValuePlusDiff cost userCost "€"
                                ]

                            [ "voiture" ] ->
                                [ span [ class "italic" ]
                                    [ text "Votre voiture actuelle" ]
                                , span [ class "italic" ]
                                    [ viewValuePlusDiff emission userEmission "kg" ]
                                , span [ class "italic" ]
                                    [ viewValuePlusDiff cost userCost "€" ]
                                ]

                            _ ->
                                []
                    )
    in
    Components.DSFR.Table.view
        { caption = Just "Comparaison avec les différentes alternatives"
        , headers =
            [ "Motorisation"
            , "Taille"
            , "Carburant"
            , "Émission annuelle (CO2eq)"
            , "Coût annuel"
            ]
        , rows = rows
        }


viewValuePlusDiff : Float -> Float -> String -> Html msg
viewValuePlusDiff value base unit =
    let
        diff =
            value - base

        tagColor =
            -- less is better
            if diff < 0 then
                "text-[var(--text-default-success)]"

            else
                "text-[var(--text-default-error)]"

        tagPrefix =
            if diff > 0 then
                "+"

            else
                ""

        formattedValue =
            H.formatFloatToFrenchLocale (Max 0) value

        formattedDiff =
            H.formatFloatToFrenchLocale (Max 0) diff
    in
    span [ class "flex gap-2" ]
        [ text (formattedValue ++ " " ++ unit)
        , if diff == 0 then
            nothing

          else
            p [ class ("rounded-full text-xs flex items-center " ++ tagColor) ]
                [ text tagPrefix
                , text formattedDiff
                ]
        ]
