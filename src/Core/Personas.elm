module Core.Personas exposing (Persona, Personas, personasDecoder)

{-| This module contains all the types and functions related to the
[`personas.yaml`](https://github.com/betagouv/publicodes-voiture/blob/main/personas.yaml)
file.

The `personas.yaml` file define a list of _persona_ that are specific
situations it can be used to test the UI or for the users to start with a
pre-filled simulation.

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Publicodes.Situation as Situation exposing (Situation)


type alias Personas =
    Dict String Persona


personasDecoder : Decoder Personas
personasDecoder =
    Decode.dict personaDecoder


type alias Persona =
    { titre : String
    , description : Maybe String
    , situation : Situation
    }


personaDecoder : Decoder Persona
personaDecoder =
    Decode.succeed Persona
        |> required "titre" string
        |> optional "description" (nullable string) Nothing
        |> required "situation" Situation.decoder
