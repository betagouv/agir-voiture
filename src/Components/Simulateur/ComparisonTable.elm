module Components.Simulateur.ComparisonTable exposing (view)

import Components.DSFR.Table
import Core.Format
import Core.Rules
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.Helpers
import Publicodes.RuleName as RuleName exposing (RuleName, SplitedRuleName)


type alias Config =
    { rawRules : RawRules
    , evaluations : Dict RuleName Evaluation
    , rulesToCompare : List SplitedRuleName
    , userCost : Float
    , userEmission : Float
    }


view : Config -> Html msg
view { rawRules, evaluations, rulesToCompare, userCost, userEmission } =
    let
        getTitle rule =
            Publicodes.Helpers.getTitle rule rawRules

        rows =
            getSortedValues evaluations rulesToCompare
                |> List.map
                    (\( name, { cost, emission } ) ->
                        case name of
                            motorisation :: gabarit :: rest ->
                                [ text <| getTitle <| RuleName.join [ "voiture", "motorisation", motorisation ]
                                , text <| getTitle <| RuleName.join [ "voiture", "gabarit", gabarit ]
                                , case rest of
                                    carburant :: [] ->
                                        text <| getTitle <| RuleName.join <| [ "voiture", "thermique", "carburant", carburant ]

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


getCostValueOf : Dict RuleName Evaluation -> SplitedRuleName -> Maybe Float
getCostValueOf evaluations name =
    ("coût" :: name)
        |> RuleName.join
        |> Core.Rules.getNumValue evaluations


getEmissionValueOf : Dict RuleName Evaluation -> SplitedRuleName -> Maybe Float
getEmissionValueOf evaluations name =
    ("empreinte" :: name)
        |> RuleName.join
        |> Core.Rules.getNumValue evaluations


getSortedValues :
    Dict RuleName Evaluation
    -> List SplitedRuleName
    -> List ( SplitedRuleName, { cost : Float, emission : Float } )
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
            Core.Format.floatToFrenchLocale (Max 0) value

        formattedDiff =
            Core.Format.floatToFrenchLocale (Max 0) diff
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
