module Components.Simulateur.TotalCard exposing (Config, new, view, withComparison, withContext)

{-| Component to display the total cost and emission of a car.
-}

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
    }


new : { id : String, title : String, cost : Float, emission : Float } -> Config
new props =
    { id = props.id
    , title = props.title
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
    { costToCompare : Float, emissionToCompare : Float }
    -> Config
    -> Config
withComparison { costToCompare, emissionToCompare } config =
    { config
        | costToCompare = Just costToCompare
        , emissionToCompare = Just emissionToCompare
    }


view : Config -> Html msg
view config =
    div [ class "rounded-md fr-my-4v outline outline-1 outline-[var(--border-plain-info)]" ]
        [ div [ class "fr-p-4v flex flex-col gap-2" ]
            [ h5 [ class "m-0" ] [ text config.title ]
            , div [ class "flex flex-col gap-2" ]
                [ div [ class "flex flex-col" ]
                    [ div [ class "flex gap-2 h-fit items-center" ]
                        [ text "Coût annuel estimé :"
                        , viewValue
                            { id = config.id ++ "-cost"
                            , value = Core.Format.floatToFrenchLocale (Max 0) config.cost
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
                                , resultType = Cost
                                }
                        )
                        config.costToCompare
                    ]
                , div [ class "flex flex-col" ]
                    [ div [ class "flex gap-2 h-fit items-center" ]
                        [ text "Émissions annuelles estimées :"
                        , viewValue
                            { id = config.id ++ "-emissions"
                            , value = Core.Format.floatToFrenchLocale (Max 0) config.emission
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
                                , resultType = Emissions
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
      -- | Large
    | Normal


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
                , ( "font-medium", props.size == Normal )
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

        formatedDiff =
            "~" ++ Core.Format.floatToFrenchLocale (Max 0) (Basics.abs diff)

        unit =
            case resultType of
                Core.Results.Cost ->
                    "€"

                Core.Results.Emissions ->
                    "kgCO2e"
    in
    if diff > 0 then
        span [ class "fr-my-1v fr-px-1v bg-[var(--background-contrast-info)] text-[var(--text-default-info)] w-fit outline outline-1 rounded-sm outline-[var(--border-plain-info)]" ]
            [ span [ class "font-medium inline-flex gap-1 items-baseline" ]
                [ text formatedDiff, viewUnit unit ]
            , case resultType of
                Core.Results.Cost ->
                    text " d'économie"

                Core.Results.Emissions ->
                    text " d'émission évitée"
            ]

    else if diff < 0 then
        span [ class "fr-my-1v fr-px-1v bg-[var(--background-contrast-warning)] text-[var(--text-default-warning)] w-fit outline outline-1 rounded-sm outline-[var(--border-plain-warning)]" ]
            [ span [ class "font-medium inline-flex gap-1 items-baseline" ]
                [ text formatedDiff, viewUnit unit ]
            , case resultType of
                Core.Results.Cost ->
                    text " de surcoût"

                Core.Results.Emissions ->
                    text " d'émission supplémentaire"
            ]

    else
        nothing


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
                            { id = ""
                            , value = value
                            , bgColor = "bg-[var(--background-default-grey)]"
                            , textColor = "text-slate-600"
                            , size = Small
                            , unit = unit
                            }
                    )
            )
        ]
