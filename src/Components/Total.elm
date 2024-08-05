module Components.Total exposing (viewParagraph)

{-|

    A component that displays the total emission and cost for the
    user car.

    @docs view

-}

import FormatNumber.Locales exposing (Decimals(..))
import Helpers
import Html exposing (..)
import Html.Attributes exposing (..)


viewParagraph : { cost : Maybe Float, emission : Maybe Float } -> Html msg
viewParagraph { cost, emission } =
    let
        format =
            Helpers.formatFloatToFrenchLocale (Max 0)
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
