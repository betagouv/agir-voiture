module Components.Simulateur.UserTotal exposing (view, viewParagraph)

{-|

    A component that displays the total emission and cost for the
    user car.

-}

import Components.Simulateur.TotalCard as TotalCard
import Core.Evaluation exposing (Evaluation)
import Core.Format
import Core.Rules as Rules
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes exposing (RawRules)
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName exposing (RuleName)


view :
    { rules : RawRules
    , evaluations : Dict RuleName Evaluation
    , cost : Maybe Float
    , emission : Maybe Float
    }
    -> Html msg
view { rules, evaluations, cost, emission } =
    case ( cost, emission ) of
        ( Just costVal, Just emissionVal ) ->
            let
                contextValues =
                    Rules.userContext
                        |> List.filterMap
                            (\name ->
                                Dict.get name evaluations
                                    |> Maybe.andThen
                                        (\{ value, unit } ->
                                            case value of
                                                NodeValue.Str optionValue ->
                                                    Just
                                                        { unit = unit
                                                        , value =
                                                            Rules.getOptionTitle
                                                                { rules = rules
                                                                , namespace = Just name
                                                                , optionValue = optionValue
                                                                }
                                                        }

                                                NodeValue.Number num ->
                                                    Just
                                                        { unit = unit
                                                        , value =
                                                            Core.Format.floatToFrenchLocale
                                                                (Max 2)
                                                                num
                                                        }

                                                NodeValue.Boolean bool ->
                                                    Just
                                                        { unit = unit
                                                        , value =
                                                            if bool then
                                                                "Oui"

                                                            else
                                                                "Non"
                                                        }

                                                _ ->
                                                    Nothing
                                        )
                            )
            in
            TotalCard.new
                { title = "Votre voiture"
                , cost = costVal
                , emission = emissionVal
                }
                |> TotalCard.withContext contextValues
                |> TotalCard.view

        _ ->
            nothing


viewParagraph : { cost : Maybe Float, emission : Maybe Float } -> Html msg
viewParagraph { cost, emission } =
    let
        format =
            Core.Format.floatToFrenchLocale (Max 0)
    in
    case ( cost, emission ) of
        ( Just costVal, Just emissionVal ) ->
            p []
                [ text "Actuellement, votre voiture vous coûte "
                , span [ class "font-medium text-[var(--text-title-blue-france)]" ]
                    [ text (format costVal ++ " €") ]
                , text " et émet "
                , span [ class "font-medium text-[var(--text-title-blue-france)]" ]
                    [ text (format emissionVal ++ " kg de CO2e") ]
                , text " par an."
                ]

        _ ->
            p []
                [ span [ class "text-[var(--text-default-error)]" ]
                    [ text """
                    Une erreur est survenue lors du calcul, veuillez
                    'Réinitialiser' et recommencer. Si le problème persiste, 
                    """
                    , a [ target "_blank", href "mailto:emile.rolley@tuta.io" ]
                        [ text "contactez-nous." ]
                    ]
                ]
