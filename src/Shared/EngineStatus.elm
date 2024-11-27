module Shared.EngineStatus exposing (EngineStatus(..), viewError)

import BetaGouv.DSFR.Alert
import Html exposing (Html)


type EngineStatus
    = NotInitialized
    | Evaluating
    | Done
    | WithError String


viewError : String -> Html msg
viewError msg =
    BetaGouv.DSFR.Alert.medium
        { title = "Une erreur est survenue lors du calcul"
        , description = Just msg
        }
        |> BetaGouv.DSFR.Alert.alert Nothing BetaGouv.DSFR.Alert.error
