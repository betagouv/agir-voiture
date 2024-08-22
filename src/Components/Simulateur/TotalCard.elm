module Components.Simulateur.TotalCard exposing (new, view, withContext)

{-| Component to display the total cost and emission of a car.
-}

import Core.Format as Format
import Core.Rules as Rules
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (viewMaybe)
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)


type alias Config =
    { title : String
    , cost : Float
    , emission : Float
    , costToCompare : Maybe Float
    , emissionToCompare : Maybe Float
    , contextToShow : Maybe (List RuleName)
    , evaluation : Dict RuleName Evaluation
    , rules : RawRules
    }


new : { title : String, cost : Float, emission : Float, rules : RawRules } -> Config
new props =
    { title = props.title
    , cost = props.cost
    , emission = props.emission
    , rules = props.rules
    , costToCompare = Nothing
    , emissionToCompare = Nothing
    , contextToShow = Nothing
    , evaluation = Dict.empty
    }


withContext : { rules : List RuleName, evaluation : Dict RuleName Evaluation } -> Config -> Config
withContext { rules, evaluation } config =
    { config
        | contextToShow = Just rules
        , evaluation = evaluation
    }


view : Config -> Html msg
view config =
    let
        round f =
            Basics.round f |> Basics.toFloat
    in
    div [ class "border rounded fr-col-8 fr-my-4v" ]
        [ div [ class "fr-px-4v fr-py-2v fr-pt-4v flex flex-col gap-2" ]
            [ h5 [ class "m-0" ] [ text "Votre voiture" ]
            , div []
                [ div [ class "flex gap-2 h-fit items-center" ]
                    [ text "Coût annuel estimé :"
                    , viewValue
                        { value = NodeValue.Number (round config.cost)
                        , unit = "€"
                        , bgColor = "bg-[var(--background-alt-purple-glycine)]"
                        , textColor = "text-[var(--text-label-purple-glycine)]"
                        , size = Normal
                        }
                    ]
                , div [ class "flex gap-2 h-fit items-center" ]
                    [ text "Émissions annuelles estimées :"
                    , viewValue
                        { value = NodeValue.Number (round config.emission)
                        , unit = "kgCO2e"
                        , bgColor = "bg-[var(--background-alt-green-bourgeon)]"
                        , textColor = "text-[var(--text-label-green-bourgeon)]"
                        , size = Normal
                        }
                    ]
                ]
            ]
        , viewMaybe
            (\context ->
                viewContext
                    { evaluations = config.evaluation
                    , context = context
                    , rules = config.rules
                    }
            )
            config.contextToShow
        ]


type ViewValueSize
    = Small
    | Normal


viewValue :
    { value : NodeValue
    , unit : String
    , bgColor : String
    , textColor : String
    , size : ViewValueSize
    }
    -> Html msg
viewValue props =
    let
        textValue =
            case props.value of
                NodeValue.Number value ->
                    Format.floatToFrenchLocale (Max 2) value

                _ ->
                    NodeValue.toString props.value
    in
    div
        [ class "rounded rounded-full fr-px-3v fr-py-1v flex gap-1 items-baseline"
        , class props.bgColor
        , class props.textColor
        ]
        [ span
            [ classList
                [ ( "font-sm", props.size == Small )
                , ( "fr-text--bold", props.size == Normal )
                ]
            ]
            [ text textValue ]
        , viewUnit props.unit
        ]


viewUnit : String -> Html msg
viewUnit unit =
    span [ class "text-sm italic" ] [ text unit ]


viewContext :
    { evaluations : Dict RuleName Evaluation
    , context : List RuleName
    , rules : RawRules
    }
    -> Html msg
viewContext { evaluations, context, rules } =
    let
        contextValues =
            context
                |> List.filterMap
                    (\name ->
                        Dict.get name evaluations
                            |> Maybe.map
                                (\{ nodeValue, unit } ->
                                    case nodeValue of
                                        NodeValue.Str optionValue ->
                                            { unit = unit
                                            , nodeValue =
                                                NodeValue.Str
                                                    (Rules.getOptionTitle
                                                        { rules = rules
                                                        , namespace = Just name
                                                        , optionValue = optionValue
                                                        }
                                                    )
                                            }

                                        _ ->
                                            { unit = unit
                                            , nodeValue = nodeValue
                                            }
                                )
                    )
    in
    div [ class "flex flex-col text-slate-600 fr-px-4v fr-py-2v gap-2 bg-[var(--background-alt-grey)] border-t " ]
        [ span [ class "font-semibold" ] [ text "Caractéristiques" ]
        , div [ class "flex gap-2" ]
            (contextValues
                |> List.map
                    (\{ nodeValue, unit } ->
                        viewValue
                            { value = nodeValue
                            , unit = Maybe.withDefault "" unit
                            , bgColor = "bg-[var(--background-default-grey)]"
                            , textColor = "text-slate-600"
                            , size = Small
                            }
                    )
            )
        ]
