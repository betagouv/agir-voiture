module Layouts.HeaderAndFooter exposing (Model, Msg, Props, layout)

import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.Icons as Icons
import Components.DSFR.Footer
import Components.DSFR.Header
import Components.DSFR.Modal
import Components.DSFR.Notice
import Components.SurveyButton
import Core.Personas exposing (Personas)
import Dict
import Effect exposing (Effect)
import Html exposing (Html, a, br, div, p, section, span, text)
import Html.Attributes exposing (class, classList, href, id, target)
import Html.Extra exposing (nothing, viewIf)
import Json.Decode
import Layout exposing (Layout)
import Publicodes.Situation exposing (Situation)
import Route exposing (Route)
import Shared
import Shared.Constants
import Shared.SimulationStep
import View exposing (View)


{-| TODO: should be two different layouts
-}
type alias Props =
    { showReactRoot : Bool
    , contrastBg : Bool
    }


layout : Props -> Shared.Model -> Route () -> Layout () Model Msg contentMsg
layout props shared _ =
    Layout.new
        { init = init
        , update = update
        , view = view props shared
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { headerMenuIsOpen : Bool }


init : () -> ( Model, Effect Msg )
init _ =
    ( { headerMenuIsOpen = False }, Effect.none )



-- UPDATE


type Msg
    = ResetSimulation
    | PersonasModalOpen
    | PersonasModalClose
    | SetPersonasSituation Situation
    | ToggleHeaderMenu


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ToggleHeaderMenu ->
            ( { model | headerMenuIsOpen = not model.headerMenuIsOpen }, Effect.none )

        ResetSimulation ->
            ( model, Effect.resetSimulation )

        PersonasModalOpen ->
            ( model, Effect.openPersonasModal )

        PersonasModalClose ->
            ( model, Effect.closePersonasModal )

        SetPersonasSituation situation ->
            ( model
            , Effect.batch
                [ Effect.setSituation situation
                , Effect.closePersonasModal
                ]
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Props -> Shared.Model -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model } -> View contentMsg
view props shared { content, toContentMsg, model } =
    { title = content.title
    , body =
        [ Components.DSFR.Header.new
            { onReset = ResetSimulation
            , onPersonasModalOpen = PersonasModalOpen
            , onToggleHeaderMenu = ToggleHeaderMenu
            , headerMenuIsOpen = model.headerMenuIsOpen
            }
            |> Components.DSFR.Header.view
            |> Html.map toContentMsg
        , viewNotice shared.decodeError
        , viewIf props.showReactRoot viewReactRoot
        , Components.DSFR.Modal.view
            { id = Shared.Constants.personasModalId
            , title = "Choisissez un profil type"
            , content = viewPersonas shared.personas
            , onClose = PersonasModalClose
            }
            |> Html.map toContentMsg
        , div
            [ class "fr-py-12v min-h-[80vh]"
            , classList
                [ ( "bg-background-main", props.contrastBg )
                , -- FIXME: should not be hardcoded like this?
                  ( "overflow-hidden", model.headerMenuIsOpen )
                , ( "fixed", model.headerMenuIsOpen )
                ]
            ]
            content.body
        , case shared.simulationStep of
            Shared.SimulationStep.Result ->
                section [ class "sticky bottom-0 w-full flex justify-center fr-py-4v bg-[var(--background-alt-blue-france)] border-t-2 border-[var(--border-default-blue-france)] z-50" ]
                    [ div [ class "fr-container flex items-center p-0 gap-4" ]
                        [ p [ class "m-0 text-[var(--text-constrat-info)] flex-1" ]
                            [ span [ class "fr-text--lg fr-text--bold text-[var(--text-label-blue-france)]" ]
                                [ text "👋 Donnez-nous votre avis !" ]
                            , text " Cet outil étant en construction, vous pouvez nous aider à l'améliorer en "
                            , span [ class "fr-text--bold text-[var(--text-label-blue-france)]" ]
                                [ text "moins de 2 minutes" ]
                            , text " en répondant à notre questionnaire."
                            ]
                        , Components.SurveyButton.view
                        ]
                    ]

            _ ->
                nothing
        , Components.DSFR.Footer.view
        ]
    }


viewReactRoot : Html msg
viewReactRoot =
    div
        [ class "fr-container" ]
        [ div [ id "react-root" ] []
        ]


viewPersonas : Personas -> Html Msg
viewPersonas personas =
    div [ class "" ]
        [ personas
            |> Dict.toList
            |> List.filterMap
                (\( _, persona ) ->
                    Maybe.map
                        (\_ ->
                            Button.new
                                { label = persona.titre
                                , onClick = Just (SetPersonasSituation persona.situation)
                                }
                                |> Button.secondary
                        )
                        persona.description
                )
            |> Button.group
            |> Button.inline
            |> Button.viewGroup
        ]


viewNotice : Maybe Json.Decode.Error -> Html msg
viewNotice decodeError =
    case decodeError of
        Just error ->
            Components.DSFR.Notice.alert
                { title = "Erreur lors de la lecture des données"
                , desc =
                    span []
                        [ text "Si le problème persiste après avoir cliqué sur 'Recommencer', vous pouvez "
                        , a [ href "mailto:emile.rolley@beta.gouv.fr", target "_blank" ]
                            [ text "nous contacter" ]
                        , text "."
                        , p [ class "text-xs fr-mt-2v fr-p-2v w-fit bg-red-50 rounded-md outline outline-1 outline-red-100 text-red-950" ]
                            [ span [ class "font-semibold fr-mb-1v" ]
                                [ text "Message d'erreur " ]
                            , br [] []
                            , text (Json.Decode.errorToString error)
                            ]
                        ]
                }

        Nothing ->
            Components.DSFR.Notice.info
                { title = "En cours de développement"
                , desc =
                    span []
                        [ text "Les résultats de ce simulateur ne sont pas stables et sont susceptibles de fortement évoluer."
                        , text " Si vous rencontrez un problème ou avez des suggestions, "
                        , a [ href "mailto:emile.rolley@beta.gouv.fr", target "_blank" ]
                            [ text "contactez-nous" ]
                        , text "."
                        ]
                }
