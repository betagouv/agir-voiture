module Components.ComparisonTable exposing (view)

import Components.DSFR.Table
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes as P


view :
    { rawRules : P.RawRules
    , evaluations : Dict P.RuleName P.Evaluation
    , rulesToCompare : List P.SplitedRuleName
    , userCost : Float
    , userEmission : Float
    }
    -> Html msg
view { rawRules, evaluations, rulesToCompare, userCost, userEmission } =
    let
        wrapUserEmission name content =
            if P.join name == H.userEmission then
                span [ class "font-medium italic" ] [ content ]

            else
                content

        getTitle =
            H.getTitle rawRules

        rows =
            getSortedValues evaluations rulesToCompare
                |> List.map
                    (\( name, { cost, emission } ) ->
                        case name of
                            motorisation :: gabarit :: rest ->
                                [ text (getTitle (P.join [ "voiture", "motorisation", motorisation ]))
                                , text (getTitle (P.join [ "voiture", "gabarit", gabarit ]))
                                , case rest of
                                    carburant :: [] ->
                                        text (getTitle (P.join [ "voiture", "thermique", "carburant", carburant ]))

                                    _ ->
                                        text ""
                                , wrapUserEmission name <| viewValuePlusDiff emission userEmission "kg"
                                , wrapUserEmission name <| viewValuePlusDiff cost userCost "€"
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


getCostValueOf : Dict P.RuleName P.Evaluation -> P.SplitedRuleName -> Maybe Float
getCostValueOf evaluations name =
    "coût"
        :: name
        |> P.join
        |> H.getNumValue evaluations


getEmissionValueOf : Dict P.RuleName P.Evaluation -> P.SplitedRuleName -> Maybe Float
getEmissionValueOf evaluations name =
    "empreinte"
        :: name
        |> P.join
        |> H.getNumValue evaluations


getSortedValues :
    Dict P.RuleName P.Evaluation
    -> List P.SplitedRuleName
    -> List ( P.SplitedRuleName, { cost : Float, emission : Float } )
getSortedValues evaluations rulesToCompare =
    rulesToCompare
        |> List.filterMap
            (\name ->
                case ( getCostValueOf evaluations name, getEmissionValueOf evaluations name ) of
                    ( Just cost, Just emission ) ->
                        Just ( name, { cost = cost, emission = emission } )

                    _ ->
                        Nothing
            )
        |> List.sortWith
            (\( _, a ) ( _, b ) ->
                -- Compare on emission first
                -- TODO: add a way to choose the comparison
                if a.emission == b.emission then
                    Basics.compare b.cost a.cost

                else
                    Basics.compare a.emission b.emission
            )


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
