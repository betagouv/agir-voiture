module Main exposing (..)

-- TODO: use Page.* instead of importing all pages

import AppUrl
import Browser exposing (Document)
import Browser.Navigation as Nav
import Core.Result
import Dict
import Effect
import File exposing (File)
import File.Download
import File.Select
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode
import Page.Documentation
import Page.Home
import Page.NotFound
import Page.Simulateur exposing (Msg(..))
import Page.Template
import Platform.Cmd as Cmd
import Publicodes.Publicodes as P exposing (Mecanism(..), NodeValue(..))
import Session as S
import Task
import Time
import Url
import Url.Parser exposing (Parser)



-- MAIN


main : Program Json.Encode.Value Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , page : Page
    }


type Page
    = Home Page.Home.Model
    | Simulateur Page.Simulateur.Model
    | Documentation Page.Documentation.Model
    | NotFound S.Data


init : Json.Encode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init encodedFlags url key =
    router url <|
        case
            Decode.decodeValue S.flagsDecoder encodedFlags
        of
            Ok flags ->
                let
                    session =
                        S.init flags
                in
                Model key (NotFound session)

            Err e ->
                let
                    emptySession =
                        S.empty
                in
                Model key (NotFound { emptySession | currentErr = Just (S.DecodeError e) })


gotoHome : Model -> ( Page.Home.Model, Cmd Page.Home.Msg ) -> ( Model, Cmd Msg )
gotoHome model ( homeModel, cmd ) =
    ( { model | page = Home homeModel }
    , Cmd.map HomeMsg cmd
    )


gotoSimulateur : Model -> ( Page.Simulateur.Model, Cmd Page.Simulateur.Msg ) -> ( Model, Cmd Msg )
gotoSimulateur model ( homeModel, cmd ) =
    ( { model | page = Simulateur homeModel }
    , Cmd.map SimulateurMsg cmd
    )


gotoDocumentation : Model -> ( Page.Documentation.Model, Cmd Page.Documentation.Msg ) -> ( Model, Cmd Msg )
gotoDocumentation model ( documentationModel, cmd ) =
    ( { model | page = Documentation documentationModel }
    , Cmd.map DocumentationMsg cmd
    )



-- EXIT


exit : Model -> S.Data
exit model =
    case model.page of
        Home m ->
            m.session

        Simulateur m ->
            m.session

        Documentation m ->
            m.session

        NotFound session ->
            session



-- ROUTING


router : Url.Url -> Model -> ( Model, Cmd Msg )
router url model =
    let
        session =
            exit model

        appUrl =
            AppUrl.fromUrl url
    in
    case appUrl.path of
        [] ->
            Page.Home.init session
                |> gotoHome model

        [ "simulateur" ] ->
            Page.Simulateur.init session
                |> gotoSimulateur model

        [ "documentation" ] ->
            -- NOTE: we may want to redirect to the corresponding rule to have a correct URL
            Page.Documentation.init session Core.Result.userEmission
                |> gotoDocumentation model

        "documentation" :: rulePath ->
            let
                ruleName =
                    String.join "/" rulePath
                        |> P.decodeRuleName
            in
            if Dict.member ruleName session.rawRules then
                Page.Documentation.init session ruleName
                    |> gotoDocumentation model

            else
                ( { model | page = NotFound session }, Cmd.none )

        _ ->
            ( { model | page = NotFound session }, Cmd.none )


route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
    Url.Parser.map handler parser



-- UPDATE


type Msg
    = NoOp
      -- Page's Msg wrappers
    | SimulateurMsg Page.Simulateur.Msg
    | DocumentationMsg Page.Documentation.Msg
      -- Navigation
    | UrlChanged Url.Url
    | UrlRequested Browser.UrlRequest
    | ReactLinkClicked String
    | EngineInitialized
    | NewEncodedSituation String
      -- Situation buttons (reset, import, export)
    | ResetSimulation
    | SelectSituationFile
    | ExportSituation
    | ImportSituationFile File
      -- Personas
    | SetPersonaSituation P.Situation
    | OpenPersonasModal
    | ClosePersonasModal
    | HomeMsg Page.Home.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HomeMsg homeMsg ->
            case model.page of
                Home m ->
                    Page.Home.update homeMsg m
                        |> gotoHome model

                _ ->
                    ( model, Cmd.none )

        SimulateurMsg simulateurMsg ->
            case model.page of
                Simulateur m ->
                    Page.Simulateur.update simulateurMsg m
                        |> gotoSimulateur model

                _ ->
                    ( model, Cmd.none )

        DocumentationMsg docMsg ->
            case model.page of
                Documentation m ->
                    Page.Documentation.update docMsg m
                        |> gotoDocumentation model

                _ ->
                    ( model, Cmd.none )

        EngineInitialized ->
            case model.page of
                Simulateur m ->
                    -- NOTE: currently, we only evalute rules in the home page,
                    -- because the evaluation is done in the Simulateur module.
                    -- However, me may want to evaluate rules in the other pages as well
                    -- (e.g. to display the result of a rule in the documentation page).
                    -- To do so, we would need to move the evaluation logic to the Main module.
                    let
                        ( newHomeModel, homeCmd ) =
                            S.updateEngineInitialized True m
                                |> Page.Simulateur.update Page.Simulateur.Evaluate
                    in
                    gotoSimulateur model ( newHomeModel, homeCmd )

                Home m ->
                    ( { model | page = Home (S.updateEngineInitialized True m) }
                    , Cmd.none
                    )

                Documentation m ->
                    ( { model | page = Documentation (S.updateEngineInitialized True m) }
                    , Cmd.none
                    )

                NotFound s ->
                    ( { model | page = NotFound { s | engineInitialized = True } }
                    , Cmd.none
                    )

        ResetSimulation ->
            updateSession
                (\session ->
                    { session
                        | situation = Dict.empty
                        , simulationStep = S.Start
                    }
                )
                model
                (Cmd.batch
                    [ Effect.setSituation (P.encodeSituation Dict.empty)
                    , Task.perform (\_ -> SimulateurMsg (NewStep S.Start)) Time.now
                    ]
                )

        ExportSituation ->
            let
                session =
                    exit model
            in
            ( model
            , P.encodeSituation session.situation
                |> Json.Encode.encode 0
                --TODO: add current date to the filename
                |> File.Download.string "simulation-agir-voiture.json" "json"
            )

        SelectSituationFile ->
            ( model, File.Select.file [ "json" ] ImportSituationFile )

        ImportSituationFile file ->
            ( model, Task.perform NewEncodedSituation (File.toString file) )

        NewEncodedSituation encodedSituation ->
            case Decode.decodeString P.situationDecoder encodedSituation of
                Ok situation ->
                    updateSituation situation model

                Err _ ->
                    ( model, Cmd.none )

        ReactLinkClicked url ->
            ( model, Nav.pushUrl model.key url )

        UrlRequested (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            router url model

        NoOp ->
            ( model, Cmd.none )

        SetPersonaSituation personaSituation ->
            let
                ( newModel, cmd ) =
                    updateSituation personaSituation model
            in
            ( newModel
            , Cmd.batch [ cmd, H.performCmdNow ClosePersonasModal ]
            )

        OpenPersonasModal ->
            let
                newModel =
                    case model.page of
                        Home m ->
                            { model | page = Home (S.openPersonasModal m) }

                        Simulateur m ->
                            { model | page = Simulateur (S.openPersonasModal m) }

                        Documentation m ->
                            { model | page = Documentation (S.openPersonasModal m) }

                        NotFound s ->
                            { model | page = NotFound { s | personasModalOpened = True } }
            in
            ( newModel, Cmd.none )

        ClosePersonasModal ->
            let
                newModel =
                    -- TODO: find a way to avoid this duplication
                    case model.page of
                        Home m ->
                            { model | page = Home (S.closePersonasModal m) }

                        Simulateur m ->
                            { model | page = Simulateur (S.closePersonasModal m) }

                        Documentation m ->
                            { model | page = Documentation (S.closePersonasModal m) }

                        NotFound s ->
                            { model | page = NotFound { s | personasModalOpened = False } }
            in
            ( newModel, Cmd.none )


updateSituation : P.Situation -> Model -> ( Model, Cmd Msg )
updateSituation newSituation model =
    updateSession (\session -> { session | situation = newSituation })
        model
        (Effect.setSituation (P.encodeSituation newSituation))


updateSession : (S.Data -> S.Data) -> Model -> Cmd Msg -> ( Model, Cmd Msg )
updateSession f model cmd =
    let
        newModel =
            case model.page of
                Home m ->
                    { model | page = Home { m | session = f m.session } }

                Simulateur m ->
                    { model | page = Simulateur { m | session = f m.session } }

                Documentation m ->
                    { model | page = Documentation { m | session = f m.session } }

                NotFound s ->
                    { model | page = NotFound (f s) }
    in
    ( newModel, cmd )



-- VIEW


view : Model -> Document Msg
view model =
    let
        session =
            exit model

        baseConfig =
            { title = ""
            , content = text ""
            , session = session
            , showReactRoot = False
            , resetSituation = ResetSimulation
            , exportSituation = ExportSituation
            , importSituation = SelectSituationFile
            , openPersonasModal = OpenPersonasModal
            , closePersonasModal = ClosePersonasModal
            , setPersonaSituation = SetPersonaSituation
            }
    in
    case model.page of
        Home m ->
            Page.Template.view
                { baseConfig
                    | title = "Accueil"
                    , content = Html.map HomeMsg (Page.Home.view m)
                }

        Simulateur m ->
            Page.Template.view
                { baseConfig
                    | title = "Simulateur"
                    , content = Html.map SimulateurMsg (Page.Simulateur.view m)
                }

        Documentation m ->
            Page.Template.view
                { baseConfig
                    | title = "Documentation" ++ " - " ++ H.getTitle session.rawRules m.rule
                    , content = Html.map DocumentationMsg (Page.Documentation.view m)
                    , showReactRoot = True
                }

        NotFound _ ->
            Page.Template.view
                { baseConfig
                    | title = "404"
                    , content = Page.NotFound.view
                }



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.engineInitialized (\_ -> EngineInitialized)
        , Effect.reactLinkClicked ReactLinkClicked
        , Sub.map SimulateurMsg Page.Simulateur.subscriptions
        ]
