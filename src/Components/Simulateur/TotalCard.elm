module Components.Simulateur.TotalCard exposing (Config, KindTag(..), new, view, withComparison, withContext, withTag)

{-| Component to display the total cost and emission of a car.
-}

import BetaGouv.DSFR.Icons as Icons
import Core.Format
import Core.Results exposing (ResultType(..))
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (Html, div, h5, span, text)
import Html.Attributes exposing (class, classList, id)
import Html.Extra exposing (nothing, viewMaybe)


type alias Config =
    { id : String
    , title : String
    , cost : Float
    , emission : Float
    , costToCompare : Maybe Float
    , emissionToCompare : Maybe Float
    , contextToShow : Maybe (List { value : String, unit : Maybe String })
    , tag : KindTag
    }


type KindTag
    = Cheapest
    | Greenest
    | None


new : { id : String, title : String, cost : Float, emission : Float } -> Config
new props =
    { id = props.id
    , title = props.title
    , cost = props.cost
    , emission = props.emission
    , costToCompare = Nothing
    , emissionToCompare = Nothing
    , contextToShow = Nothing
    , tag = None
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
    { costToCompare : Float, emissionToCompare : Float }
    -> Config
    -> Config
withComparison { costToCompare, emissionToCompare } config =
    { config
        | costToCompare = Just costToCompare
        , emissionToCompare = Just emissionToCompare
    }


withTag : KindTag -> Config -> Config
withTag tag config =
    { config | tag = tag }


view : Config -> Html msg
view config =
    div [ class "rounded-xl fr-my-4v border border-[var(--border-contrast-grey)]" ]
        [ div [ class "fr-p-4v flex flex-col gap-2" ]
            [ viewTag config.tag
            , h5 [ class "mt-2 mb-0" ] [ text config.title ]
            , div [ class "flex flex-col gap-2" ]
                [ div [ id (config.id ++ "-cost"), class "flex items-center" ]
                    [ span [ class "mr-2" ] [ text "Coût annuel :" ]
                    , span [ class "flex gap-1 items-center h-min" ]
                        [ span [ class "text-lg font-semibold" ]
                            [ text <| Core.Format.humanReadable config.cost ]
                        , span [ class "" ] [ text "€" ]
                        , viewMaybe
                            (\baseCost ->
                                viewDiff
                                    { value = config.cost
                                    , base = baseCost
                                    , resultType = Cost
                                    }
                            )
                            config.costToCompare
                        ]
                    ]
                , div [ id (config.id ++ "-emissions"), class "flex items-center" ]
                    [ span [ class "mr-2" ] [ text "Émissions annuelles :" ]
                    , span [ class "flex gap-1 items-center h-min" ]
                        [ span [ class "text-lg font-semibold" ]
                            [ text <| Core.Format.humanReadable config.emission ]
                        , span [ class "" ] [ text "kgCO2e" ]
                        , viewMaybe
                            (\baseEmission ->
                                viewDiff
                                    { value = config.emission
                                    , base = baseEmission
                                    , resultType = Emissions
                                    }
                            )
                            config.emissionToCompare
                        ]
                    ]
                ]
            ]
        , viewMaybe viewContext config.contextToShow
        ]


type ViewValueSize
    = Small



-- | Large
-- | Normal


viewValue :
    { id : String
    , value : String
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
        , id props.id
        ]
        [ span
            [ classList
                [ ( "text-sm", props.size == Small )

                -- , ( "fr-text--bold", props.size == Large )
                -- , ( "font-medium", props.size == Normal )
                ]
            ]
            [ text props.value ]
        , props.unit
            |> Maybe.map viewUnit
            |> Maybe.withDefault
                -- FIXME: should not be hardcoded like this
                nothing
        ]


viewUnit : String -> Html msg
viewUnit unit =
    span [ class "text-sm italic" ] [ text unit ]


viewDiff : { value : Float, base : Float, resultType : ResultType } -> Html msg
viewDiff { value, base, resultType } =
    let
        diff =
            base - value

        sign =
            if diff > 0 then
                "-"

            else
                "+"

        formatedDiff =
            sign
                ++ (case resultType of
                        Core.Results.Cost ->
                            Core.Format.floatToFrenchLocale (Max 0) (Basics.abs diff)

                        Core.Results.Emissions ->
                            let
                                percentGain =
                                    100 - (value * 100 / base)
                            in
                            Core.Format.withPrecision (Max 0) (Basics.abs percentGain)
                   )

        unit =
            case resultType of
                Core.Results.Cost ->
                    "€"

                Core.Results.Emissions ->
                    "%"
    in
    if diff > 0 then
        span [ class "fr-my-1v fr-px-2v bg-[var(--background-contrast-success)] text-[var(--text-default-success)] w-fit rounded-full" ]
            [ span [ class "font-medium inline-flex gap-1 items-baseline" ]
                [ text formatedDiff, viewUnit unit ]
            ]

    else if diff < 0 then
        span [ class "fr-my-1v fr-px-2v bg-[var(--background-contrast-warning)] text-[var(--text-default-warning)] w-fit rounded-full" ]
            [ span [ class "font-medium inline-flex gap-1 items-baseline" ]
                [ text formatedDiff, viewUnit unit ]
            ]

    else
        nothing


viewContext :
    List { value : String, unit : Maybe String }
    -> Html msg
viewContext contextValues =
    div [ class "flex gap-2 flex-wrap p-4 gap-2 border-t border-[var(--border-default-grey)]" ]
        (contextValues
            |> List.map
                (\{ value, unit } ->
                    viewValue
                        { id = ""
                        , value = value
                        , bgColor = "bg-[var(--background-alt-blue-france)]"
                        , textColor = "text-[var(--text-label-blue-france)]"
                        , size = Small
                        , unit = unit
                        }
                )
        )


viewTag : KindTag -> Html msg
viewTag tag =
    case tag of
        Cheapest ->
            span [ class "flex justify-center w-fit font-medium fr-px-3v fr-py-1v bg-amber-100 text-amber-700 rounded-full" ]
                [ Icons.iconSM Icons.finance.moneyEuroCircleFill
                , span [ class "fr-pl-1v" ] [ text "La plus économique" ]
                ]

        Greenest ->
            span [ class "flex justify-center w-fit font-medium fr-px-3v fr-py-1v bg-green-100 text-green-700 rounded-full" ]
                [ Icons.iconSM Icons.others.leafFill
                , span [ class "fr-pl-1v" ] [ text "La plus écologique" ]
                ]

        None ->
            nothing
