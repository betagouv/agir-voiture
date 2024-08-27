module Components.Simulateur.TotalCard exposing (new, view, withComparison, withContext)

{-| Component to display the total cost and emission of a car.
-}

import BetaGouv.DSFR.Icons as Icons
import Core.Format
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing, viewMaybe)


type alias Config =
    { title : String
    , cost : Float
    , emission : Float
    , costToCompare : Maybe Float
    , emissionToCompare : Maybe Float
    , contextToShow : Maybe (List { value : String, unit : Maybe String })
    }


new : { title : String, cost : Float, emission : Float } -> Config
new props =
    { title = props.title
    , cost = props.cost
    , emission = props.emission
    , costToCompare = Nothing
    , emissionToCompare = Nothing
    , contextToShow = Nothing
    }


withContext :
    List { value : String, unit : Maybe String }
    -> Config
    -> Config
withContext context config =
    { config
        | contextToShow = Just context
    }


withComparison :
    { costToCompare : Maybe Float, emissionToCompare : Maybe Float }
    -> Config
    -> Config
withComparison { costToCompare, emissionToCompare } config =
    { config
        | costToCompare = costToCompare
        , emissionToCompare = emissionToCompare
    }


view : Config -> Html msg
view config =
    div [ class "outline rounded-md fr-my-4v outline-1 outline-[var(--border-plain-info)]" ]
        [ div [ class "fr-px-4v fr-py-4v flex flex-col gap-2" ]
            [ h5 [ class "m-0" ] [ text config.title ]
            , div [ class "flex flex-col gap-2" ]
                [ div [ class "flex flex-col" ]
                    [ div [ class "flex gap-2 h-fit items-center" ]
                        [ text "Coût annuel estimé :"
                        , viewValue
                            { value = Core.Format.floatToFrenchLocale (Max 0) config.cost
                            , unit = Just "€"
                            , bgColor = "bg-[var(--background-alt-purple-glycine)]"
                            , textColor = "text-[var(--text-label-purple-glycine)]"
                            , size = Normal
                            }
                        ]
                    , viewMaybe
                        (\baseCost ->
                            viewDiff
                                { value = config.cost
                                , base = baseCost
                                , unit = "€"
                                }
                        )
                        config.costToCompare
                    ]
                , div [ class "flex flex-col" ]
                    [ div [ class "flex gap-2 h-fit items-center" ]
                        [ text "Émissions annuelles estimées :"
                        , viewValue
                            { value = Core.Format.floatToFrenchLocale (Max 0) config.emission
                            , unit = Just "kgCO2e"
                            , bgColor = "bg-[var(--background-alt-green-bourgeon)]"
                            , textColor = "text-[var(--text-label-green-bourgeon)]"
                            , size = Normal
                            }
                        ]
                    , viewMaybe
                        (\baseEmission ->
                            viewDiff
                                { value = config.emission
                                , base = baseEmission
                                , unit = "kgCO2e"
                                }
                        )
                        config.emissionToCompare
                    ]
                ]
            ]
        , viewMaybe viewContext config.contextToShow
        ]


type ViewValueSize
    = Small
    | Normal
    | Large


viewValue :
    { value : String
    , unit : Maybe String
    , bgColor : String
    , textColor : String
    , size : ViewValueSize
    }
    -> Html msg
viewValue props =
    span
        [ class "rounded rounded-full fr-px-3v fr-py-1v flex gap-1 items-baseline "
        , class props.bgColor
        , class props.textColor
        ]
        [ span
            [ classList
                [ ( "text-sm", props.size == Small )
                , ( "fr-text--bold", props.size == Large )
                , ( "font-medium", props.size == Normal )
                ]
            ]
            [ text props.value ]
        , props.unit
            |> Maybe.map viewUnit
            |> Maybe.withDefault
                -- FIXME: should not be hardcoded like this
                (case props.value of
                    -- "Thermique" ->
                    --     Icons.iconSM Icons.map.gasStationFill
                    --
                    -- "Électrique" ->
                    --     Icons.iconSM Icons.map.chargingPile2Fill
                    --
                    -- "Hybride" ->
                    --     Icons.iconSM Icons.map.chargingPile2Line
                    _ ->
                        nothing
                )
        ]


viewUnit : String -> Html msg
viewUnit unit =
    span [ class "text-sm italic" ] [ text unit ]


viewDiff : { value : Float, base : Float, unit : String } -> Html msg
viewDiff { value, base, unit } =
    let
        diff =
            Basics.abs (value - base)
    in
    span [ class "fr-my-1v fr-px-1v bg-[var(--background-contrast-info)] text-[var(--text-default-info)] w-fit outline outline-1 rounded-sm outline-[var(--border-plain-info)]" ]
        [ span [ class "font-medium inline-flex gap-1 items-baseline" ]
            [ text ("~" ++ Core.Format.floatToFrenchLocale (Max 0) diff)
            , viewUnit unit
            ]
        , text " d'économie"
        ]


viewContext :
    List { value : String, unit : Maybe String }
    -> Html msg
viewContext contextValues =
    div [ class "flex flex-col fr-px-4v fr-pt-2v fr-pb-4v gap-2 bg-[var(--background-contrast-info)]" ]
        [ span [ class "font-semibold" ] [ text "Contexte" ]
        , div [ class "flex gap-2 flex-wrap" ]
            (contextValues
                |> List.map
                    (\{ value, unit } ->
                        viewValue
                            { value = value
                            , bgColor = "bg-[var(--background-default-grey)]"
                            , textColor = "text-slate-600"
                            , size = Small
                            , unit = unit
                            }
                    )
            )
        ]
