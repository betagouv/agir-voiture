module Session exposing (..)

import Core.Personas as Personas exposing (Personas)
import Core.UI as UI
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Publicodes.Publicodes as P



-- FLAGS
--
-- NOTE: Flags are used to pass data from outside the Elm runtime into the Elm
-- program (i.e. from the main.ts file to the Elm app).
--


type SimulationStep
    = Category UI.Category
    | Result
    | Start


simulationStepDecoder : Decode.Decoder SimulationStep
simulationStepDecoder =
    Decode.map
        (\s ->
            case s of
                "Result" ->
                    Result

                "Start" ->
                    Start

                _ ->
                    Category s
        )
        Decode.string


simulationStepEncoder : SimulationStep -> Encode.Value
simulationStepEncoder step =
    case step of
        Category category ->
            Encode.string category

        Result ->
            Encode.string "Result"

        Start ->
            Encode.string "Start"


type alias Flags =
    { rules : P.RawRules
    , ui : UI.Data
    , personas : Personas
    , situation : P.Situation
    , simulationStep : SimulationStep
    }


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.succeed Flags
        |> Decode.required "rules" P.rawRulesDecoder
        |> Decode.required "ui" UI.uiDecoder
        |> Decode.required "personas" Personas.personasDecoder
        |> Decode.required "situation" P.situationDecoder
        |> Decode.required "simulationStep" simulationStepDecoder


{-| TODO: should [rawRules] and [ui] stored here?
-}
type alias Data =
    { engineInitialized : Bool
    , situation : P.Situation
    , currentErr : Maybe AppError
    , rawRules : P.RawRules
    , ui : UI.Data
    , personas : Personas
    , personasModalOpened : Bool
    , simulationStep : SimulationStep
    }


{-| Extensible record type alias for models that include a [Data] session.
-}
type alias WithSession a =
    { a | session : Data }


type AppError
    = DecodeError Decode.Error
    | UnvalidSituationFile


empty : Data
empty =
    { engineInitialized = False
    , rawRules = Dict.empty
    , situation = Dict.empty
    , ui = UI.empty
    , personas = Dict.empty
    , currentErr = Nothing
    , personasModalOpened = False
    , simulationStep = Start
    }


init : Flags -> Data
init { rules, situation, ui, personas, simulationStep } =
    { empty
        | rawRules = rules
        , situation = situation
        , ui = ui
        , personas = personas
        , simulationStep = simulationStep
    }



-- UPDATE SITUATION HELPERS


updateEngineInitialized : Bool -> WithSession model -> WithSession model
updateEngineInitialized b model =
    let
        session =
            model.session
    in
    { model | session = { session | engineInitialized = b } }


{-| NOTE: this could only accept a [P.Situation] as argument, but it's more flexible this way.
-}
updateSituation : (P.Situation -> P.Situation) -> WithSession model -> WithSession model
updateSituation f model =
    let
        session =
            model.session
    in
    { model | session = { session | situation = f session.situation } }


updateError : (Maybe AppError -> Maybe AppError) -> WithSession model -> WithSession model
updateError f model =
    let
        session =
            model.session
    in
    { model | session = { session | currentErr = f session.currentErr } }


openPersonasModal : WithSession model -> WithSession model
openPersonasModal model =
    updatePersonasModalOpened True model


closePersonasModal : WithSession model -> WithSession model
closePersonasModal model =
    updatePersonasModalOpened False model


updatePersonasModalOpened : Bool -> WithSession model -> WithSession model
updatePersonasModalOpened b model =
    let
        session =
            model.session
    in
    { model | session = { session | personasModalOpened = b } }


updateCurrentStep : SimulationStep -> WithSession model -> WithSession model
updateCurrentStep step model =
    let
        session =
            model.session
    in
    { model | session = { session | simulationStep = step } }



-- VIEW HELPERS


viewError : Maybe AppError -> Html msg
viewError maybeError =
    case maybeError of
        Just (DecodeError e) ->
            div [ class "alert alert-error flex" ]
                [ {- Views.Icons.error -} span [] [ text (Decode.errorToString e) ]
                ]

        Just UnvalidSituationFile ->
            div [ class "alert alert-error flex" ]
                [ {- Views.Icons.error -} span [] [ text "Le fichier renseigné ne contient pas de situation valide." ]
                ]

        Nothing ->
            text ""
