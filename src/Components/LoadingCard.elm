module Components.LoadingCard exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)


view : Html msg
view =
    div [ class "border rounded fr-col-8 fr-p-6v fr-my-6v" ]
        [ div [ class "flex flex-col gap-3" ]
            [ div [ class "animate-pulse bg-slate-300 h-5 w-1/4 fr-mb-4v" ] []
            , div [ class "animate-pulse bg-slate-200 h-8 w-3/4" ] []
            , div [ class "animate-pulse bg-slate-200 h-8 w-3/4" ] []
            ]
        ]
