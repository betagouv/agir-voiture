module Components.Simulateur.ComparisonTable exposing (view)

import Components.DSFR.Table
import Core.Format
import Core.Result exposing (ComputedResult(..))
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)


type alias Config =
    { rulesToCompare : List ComputedResult
    , userCost : Float
    , userEmission : Float
    }


view : Config -> Html msg
view { rulesToCompare, userCost, userEmission } =
    let
        compare a b =
            -- Compare on emission first
            -- TODO: add a way to choose the comparison
            if a.emission == b.emission then
                Basics.compare b.cost a.cost

            else
                Basics.compare a.emission b.emission

        rows =
            rulesToCompare
                |> List.sortWith
                    (\a b ->
                        case ( a, b ) of
                            ( AlternativeCar carA, AlternativeCar carB ) ->
                                compare carA carB

                            ( CurrentUserCar user, AlternativeCar car ) ->
                                compare user car

                            ( AlternativeCar car, CurrentUserCar user ) ->
                                compare car user

                            ( CurrentUserCar userA, CurrentUserCar userB ) ->
                                -- Should not happen
                                compare userA userB
                    )
                |> List.map
                    (\result ->
                        let
                            _ =
                                Debug.log "result" result
                        in
                        case result of
                            AlternativeCar infos ->
                                [ text infos.motorisation
                                , text infos.gabarit
                                , text (Maybe.withDefault "Éléctricité" infos.carburant)
                                , viewValuePlusDiff infos.emission userEmission "kg"
                                , viewValuePlusDiff infos.cost userCost "€"
                                ]

                            CurrentUserCar { emission, cost } ->
                                [ span [ class "italic" ]
                                    [ text "Votre voiture actuelle" ]
                                , span [ class "italic" ]
                                    [ viewValuePlusDiff emission userEmission "kg" ]
                                , span [ class "italic" ]
                                    [ viewValuePlusDiff cost userCost "€" ]
                                ]
                    )
    in
    Components.DSFR.Table.view
        { caption = Just "Toutes les alternatives"
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
