module Core.Personas exposing (..)

{-| This module contains all the types and functions related to the
[`personas.yaml`](https://github.com/betagouv/publicodes-voiture/blob/main/personas.yaml)
file.

The `personas.yaml` file define a list of _persona_ that are specific
situations it can be used to test the UI or for the users to start with a
pre-filled simulation.

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Publicodes.Situation as Situation exposing (Situation)


type alias Personas =
    Dict String Persona


personasDecoder : Decoder Personas
personasDecoder =
    Decode.dict personaDecoder


type alias Persona =
    { titre : String
    , description : String
    , situation : Situation
    }


personaDecoder : Decoder Persona
personaDecoder =
    Decode.succeed Persona
        |> required "titre" string
        |> required "description" string
        |> required "situation" Situation.decoder
