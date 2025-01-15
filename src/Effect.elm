port module Effect exposing
    ( Effect
    , none, batch
    , sendCmd, sendMsg
    , pushRoute, replaceRoute
    , pushRoutePath, replaceRoutePath
    , loadExternalUrl, back
    , map, toCmd
    , closePersonasModal, downloadSituation, evaluate, evaluateAll, evaluateAlternatives, evaluateResults, evaluateTargetCar, evaluateUserCar, newInputError, onEngineError, onEngineInitialized, onEvaluatedAlternatives, onEvaluatedResults, onEvaluatedRules, onEvaluatedTargetCar, onEvaluatedUserCar, onReactLinkClicked, onSituationUpdated, openPersonasModal, removeInputError, resetSimulation, restartEngine, scrollToTop, setSimulationStep, setSituation, updateSituation
    )

{-|

@docs Effect

@docs none, batch
@docs sendCmd, sendMsg

@docs pushRoute, replaceRoute
@docs pushRoutePath, replaceRoutePath
@docs loadExternalUrl, back

@docs map, toCmd

-}

import Browser.Navigation
import Dict exposing (Dict)
import Json.Encode
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation as Situation exposing (Situation)
import Route
import Route.Path exposing (Path(..))
import Shared.Constants
import Shared.Model
import Shared.Msg
import Shared.SimulationStep as SimulationStep exposing (SimulationStep)
import Task
import Url exposing (Url)


type Effect msg
    = -- BASICS
      None
    | Batch (List (Effect msg))
    | SendCmd (Cmd msg)
      -- ROUTING
    | PushUrl String
    | ReplaceUrl String
    | LoadExternalUrl String
    | Back
      -- SHARED
    | SendSharedMsg Shared.Msg.Msg
      -- JS INTEROP
    | SendToJs { tag : String, data : Json.Encode.Value }



-- CUSTOM


evaluate : Effect msg
evaluate =
    SendSharedMsg Shared.Msg.Evaluate


resetSimulation : Effect msg
resetSimulation =
    SendSharedMsg Shared.Msg.ResetSimulation


newInputError : { name : RuleName, value : String, msg : String } -> Effect msg
newInputError error =
    SendSharedMsg (Shared.Msg.NewInputError error)


removeInputError : RuleName -> Effect msg
removeInputError name =
    SendSharedMsg (Shared.Msg.RemoveInputError name)


setSituation : Situation -> Effect msg
setSituation situation =
    batch
        [ SendSharedMsg (Shared.Msg.SetSituation situation)
        , SendToJs
            { tag = "SET_SITUATION"
            , data = Situation.encode situation
            }
        ]


setSimulationStep : SimulationStep -> Effect msg
setSimulationStep step =
    batch
        [ SendSharedMsg (Shared.Msg.SetSimulationStep step)
        , SendToJs
            { tag = "SET_SIMULATION_STEP"
            , data = SimulationStep.encode step
            }
        ]


evaluateAll : List RuleName -> Effect msg
evaluateAll ruleNames =
    SendToJs
        { tag = "EVALUATE_ALL"
        , data = Json.Encode.list Json.Encode.string ruleNames
        }


evaluateResults : Effect msg
evaluateResults =
    SendToJs
        { tag = "EVALUATE_RESULTS"
        , data = Json.Encode.null
        }


evaluateUserCar : Effect msg
evaluateUserCar =
    SendToJs
        { tag = "EVALUATE_USER_CAR"
        , data = Json.Encode.null
        }


evaluateAlternatives : Effect msg
evaluateAlternatives =
    SendToJs
        { tag = "EVALUATE_ALTERNATIVES"
        , data = Json.Encode.null
        }


evaluateTargetCar : Effect msg
evaluateTargetCar =
    SendToJs
        { tag = "EVALUATE_TARGET_CAR"
        , data = Json.Encode.null
        }


updateSituation : ( RuleName, NodeValue ) -> Effect msg
updateSituation ( name, value ) =
    batch
        [ SendSharedMsg (Shared.Msg.UpdateSituation ( name, value ))
        , SendToJs
            { tag = "UPDATE_SITUATION"
            , data =
                Json.Encode.object
                    [ ( "name", Json.Encode.string name )
                    , ( "value", NodeValue.encode value )
                    ]
            }
        ]


restartEngine : Effect msg
restartEngine =
    SendToJs
        { tag = "RESTART_ENGINE"
        , data = Json.Encode.null
        }


downloadSituation : Effect msg
downloadSituation =
    SendToJs
        { tag = "DOWNLOAD_SITUATION"
        , data = Json.Encode.null
        }



-- PORTS


port outgoing :
    { tag : String
    , data : Json.Encode.Value
    }
    -> Cmd msg


openPersonasModal : Effect msg
openPersonasModal =
    openModal Shared.Constants.personasModalId


closePersonasModal : Effect msg
closePersonasModal =
    closeModal Shared.Constants.personasModalId


openModal : String -> Effect msg
openModal modalId =
    SendToJs
        { tag = "OPEN_MODAL"
        , data = Json.Encode.string modalId
        }


closeModal : String -> Effect msg
closeModal modalId =
    SendToJs
        { tag = "CLOSE_MODAL"
        , data = Json.Encode.string modalId
        }


scrollToTop : Effect msg
scrollToTop =
    SendToJs
        { tag = "SCROLL_TO_TOP"
        , data = Json.Encode.null
        }



-- PORTS (SUBSCRIPTIONS)


{-| A link was clicked on the custom `RulePage` component.

The link is a string that represents the URL of the page to navigate to.

-}
port onReactLinkClicked : (String -> msg) -> Sub msg


{-| Received a list of rules with their corresponding evaluation result.
-}
port onEvaluatedRules : (List ( RuleName, Json.Encode.Value ) -> msg) -> Sub msg


{-| The situation has correctly been updated in the JS side.
-}
port onSituationUpdated : (() -> msg) -> Sub msg


{-| The engine has been initialized.
-}
port onEngineInitialized : (() -> msg) -> Sub msg


{-| The engine threw an error.
-}
port onEngineError : (String -> msg) -> Sub msg


{-| Received the results from the CarSimulator engine.
-}
port onEvaluatedResults : (Json.Encode.Value -> msg) -> Sub msg


port onEvaluatedUserCar : (Json.Encode.Value -> msg) -> Sub msg


port onEvaluatedAlternatives : (Json.Encode.Value -> msg) -> Sub msg


port onEvaluatedTargetCar : (Json.Encode.Value -> msg) -> Sub msg



-- BASICS


{-| Don't send any effect.
-}
none : Effect msg
none =
    None


{-| Send multiple effects at once.
-}
batch : List (Effect msg) -> Effect msg
batch =
    Batch


{-| Send a normal `Cmd msg` as an effect, something like `Http.get` or `Random.generate`.
-}
sendCmd : Cmd msg -> Effect msg
sendCmd =
    SendCmd


{-| Send a message as an effect. Useful when emitting events from UI components.
-}
sendMsg : msg -> Effect msg
sendMsg msg =
    Task.succeed msg
        |> Task.perform identity
        |> SendCmd



-- ROUTING


{-| Set the new route, and make the back button go back to the current route.
-}
pushRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
pushRoute route =
    PushUrl (Route.toString route)


{-| Same as `Effect.pushRoute`, but without `query` or `hash` support
-}
pushRoutePath : Route.Path.Path -> Effect msg
pushRoutePath path =
    PushUrl (Route.Path.toString path)


{-| Set the new route, but replace the previous one, so clicking the back
button **won't** go back to the previous route.
-}
replaceRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
replaceRoute route =
    ReplaceUrl (Route.toString route)


{-| Same as `Effect.replaceRoute`, but without `query` or `hash` support
-}
replaceRoutePath : Route.Path.Path -> Effect msg
replaceRoutePath path =
    ReplaceUrl (Route.Path.toString path)


{-| Redirect users to a new URL, somewhere external to your web application.
-}
loadExternalUrl : String -> Effect msg
loadExternalUrl =
    LoadExternalUrl


{-| Navigate back one page
-}
back : Effect msg
back =
    Back



-- INTERNALS


{-| Elm Land depends on this function to connect pages and layouts
together into the overall app.
-}
map : (msg1 -> msg2) -> Effect msg1 -> Effect msg2
map fn effect =
    case effect of
        None ->
            None

        Batch list ->
            Batch (List.map (map fn) list)

        SendCmd cmd ->
            SendCmd (Cmd.map fn cmd)

        PushUrl url ->
            PushUrl url

        ReplaceUrl url ->
            ReplaceUrl url

        Back ->
            Back

        LoadExternalUrl url ->
            LoadExternalUrl url

        SendSharedMsg sharedMsg ->
            SendSharedMsg sharedMsg

        SendToJs payload ->
            SendToJs payload


{-| Elm Land depends on this function to perform your effects.
-}
toCmd :
    { key : Browser.Navigation.Key
    , url : Url
    , shared : Shared.Model.Model
    , fromSharedMsg : Shared.Msg.Msg -> msg
    , batch : List msg -> msg
    , toCmd : msg -> Cmd msg
    }
    -> Effect msg
    -> Cmd msg
toCmd options effect =
    case effect of
        None ->
            Cmd.none

        Batch list ->
            Cmd.batch (List.map (toCmd options) list)

        SendCmd cmd ->
            cmd

        PushUrl url ->
            Browser.Navigation.pushUrl options.key url

        ReplaceUrl url ->
            Browser.Navigation.replaceUrl options.key url

        Back ->
            Browser.Navigation.back options.key 1

        LoadExternalUrl url ->
            Browser.Navigation.load url

        SendSharedMsg sharedMsg ->
            Task.succeed sharedMsg
                |> Task.perform options.fromSharedMsg

        SendToJs payload ->
            outgoing payload
