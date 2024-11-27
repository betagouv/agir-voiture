module Components.Simulateur.UserTotal exposing (view)

{-|

    A component that displays the total emission and cost for the
    user car.

-}

import Components.Simulateur.TotalCard as TotalCard
import Core.Evaluation exposing (Evaluation)
import Core.Format
import Core.Results.CarInfos exposing (CarInfos)
import Core.Rules as Rules
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (Html)
import Publicodes exposing (RawRules)
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName exposing (RuleName)


view :
    { rules : RawRules
    , evaluations : Dict RuleName Evaluation
    , user : CarInfos
    }
    -> Html msg
view { rules, evaluations, user } =
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
        , cost = user.cost.value
        , emission = user.emissions.value
        }
        |> TotalCard.withContext contextValues
        |> TotalCard.view
