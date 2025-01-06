module Components.Simulateur.ComparisonTable exposing (view)

import Components.DSFR.Table
import Core.Format
import Core.Results exposing (Results)
import Core.Results.Alternative exposing (Alternative(..))
import Core.Results.CarInfos exposing (CarInfos)
import Core.Results.RuleValue as RuleValue
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (Html, span, text)
import Html.Attributes exposing (class, title)
import Html.Extra exposing (nothing)


{-| Displays a table comparing all alternatives (only BuyNewCar for now)

TODO: support all alternatives

-}
view : Results -> Html msg
view { alternatives, user } =
    let
        rows =
            alternatives
                |> List.filterMap
                    (\alternative ->
                        case alternative of
                            BuyNewCar infos ->
                                Just infos

                            _ ->
                                Nothing
                    )
                |> List.sortWith (\a b -> compareCarInfos a b)
                |> List.map
                    (\infos ->
                        [ text (RuleValue.title infos.motorisation)
                        , text (RuleValue.title infos.size)
                        , text
                            (Maybe.map RuleValue.title infos.fuel
                                |> Maybe.withDefault "Électricité"
                            )
                        , viewValuePlusDiff
                            infos.emissions.value
                            user.emissions.value
                            "kgCO2e"
                        , viewValuePlusDiff infos.cost.value user.cost.value "€"
                        ]
                    )
    in
    Components.DSFR.Table.view
        { caption = Just "Tableau comparatif des toutes les alternatives"
        , headers =
            [ "Motorisation"
            , "Taille"
            , "Carburant"
            , "Émission annuelle"
            , "Coût annuel"
            ]
        , rows = rows
        }


{-| Compares on emission first.
TODO: add a way to choose the comparison
-}
compareCarInfos : CarInfos -> CarInfos -> Basics.Order
compareCarInfos a b =
    if a.emissions == b.emissions then
        Basics.compare b.cost.value a.cost.value

    else
        Basics.compare b.emissions.value a.emissions.value


viewValuePlusDiff : Float -> Float -> String -> Html msg
viewValuePlusDiff value base unit =
    let
        diff =
            value - base

        formattedValue =
            Core.Format.floatToFrenchLocale (Max 0) value
    in
    span [ class "flex gap-2 items-center" ]
        [ span []
            [ text formattedValue
            , span [ class "fr-pl-1v text-xs text-neutral-600" ] [ text unit ]
            ]
        , if diff == 0 then
            nothing

          else
            let
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

                formattedDiff =
                    Core.Format.floatToFrenchLocale (Max 0) diff
            in
            span [ class ("flex text-xs items-center " ++ tagColor) ]
                [ text tagPrefix
                , span [ title "Différence par rapport à votre situation actuelle" ]
                    [ text formattedDiff ]
                ]
        ]
