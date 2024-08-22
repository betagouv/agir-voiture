module Components.Simulateur.UserTotal exposing (view, viewParagraph)

{-|

    A component that displays the total emission and cost for the
    user car.

-}

import Components.Simulateur.TotalCard as TotalCard
import Core.Format
import Core.Rules
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing)
import Publicodes exposing (Evaluation, RawRules)
import Publicodes.RuleName exposing (RuleName)


view :
    { rules : RawRules
    , evaluation : Dict RuleName Evaluation
    , cost : Maybe Float
    , emission : Maybe Float
    }
    -> Html msg
view { rules, evaluation, cost, emission } =
    case ( cost, emission ) of
        ( Just costVal, Just emissionVal ) ->
            TotalCard.new
                { title = "Votre voiture"
                , cost = costVal
                , emission = emissionVal
                , rules = rules
                }
                |> TotalCard.withContext
                    { rules = Core.Rules.userContext
                    , evaluation = evaluation
                    }
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
