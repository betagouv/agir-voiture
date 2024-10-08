module Components.Simulateur.Questions exposing (view)

import BetaGouv.DSFR.Input
import Components.Select
import Components.Simulateur.BooleanInput
import Components.Simulateur.Navigation
import Components.Simulateur.NumericInput
import Components.Simulateur.Stepper
import Core.InputError exposing (InputError)
import Core.Rules as Rules
import Core.UI as UI
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Helper exposing (viewMarkdown)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (nothing, viewMaybe)
import Markdown
import Publicodes exposing (Evaluation, Mechanism(..), RawRule, RawRules)
import Publicodes.NodeValue as NodeValue exposing (NodeValue(..))
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation exposing (Situation)
import Shared.SimulationStep as SimulationStep exposing (SimulationStep)


type alias Config msg =
    { rules : RawRules
    , situation : Situation
    , evaluations : Dict RuleName Evaluation
    , categories : List UI.Category
    , category : UI.Category
    , onInput : RuleName -> NodeValue -> Maybe InputError -> msg
    , questions : List RuleName
    , onNewStep : SimulationStep -> msg
    , inputErrors : Dict RuleName { msg : String, value : String }
    , currentStep : SimulationStep
    }


view : Config msg -> Html msg
view props =
    let
        containsErrorsForApplicableQuestions =
            props.inputErrors
                |> Dict.toList
                |> List.filter
                    (\( name, _ ) ->
                        Dict.get name props.evaluations
                            |> Maybe.map .isApplicable
                            |> Maybe.withDefault False
                    )
                |> List.isEmpty
                |> not
    in
    div []
        [ Components.Simulateur.Stepper.view
            { rules = props.rules
            , categories = props.categories
            , currentStep = props.currentStep
            }
        , viewCategoryDescription props.category props.rules
        , hr [] []
        , viewQuestions props
        , Components.Simulateur.Navigation.view
            { categories = props.categories
            , onNewStep = props.onNewStep
            , currentStep = SimulationStep.Category props.category
            , containsErrors = containsErrorsForApplicableQuestions
            }
        ]


viewCategoryDescription : String -> RawRules -> Html msg
viewCategoryDescription currentCategory rawRules =
    div [ class "text-[var(--text-mention-grey)]" ]
        [ Dict.get
            currentCategory
            rawRules
            |> Maybe.andThen .description
            |> viewMaybe viewMarkdown
        ]


viewQuestions : Config msg -> Html msg
viewQuestions props =
    div [ class "fr-container--fluid" ]
        [ div [ class "fr-grid-row gap-6" ]
            (props.questions
                |> List.filterMap
                    (\name ->
                        Maybe.map2
                            (\rule eval ->
                                if eval.isApplicable then
                                    div [ class "fr-col-8" ]
                                        [ viewQuestion props ( name, rule )
                                        ]

                                else
                                    nothing
                            )
                            (Dict.get name props.rules)
                            (Dict.get name props.evaluations)
                    )
            )
        ]


viewQuestion : Config msg -> ( RuleName, RawRule ) -> Html msg
viewQuestion props ( name, rule ) =
    rule.question
        |> Maybe.map
            (\question ->
                viewInput props question ( name, rule )
            )
        |> viewMaybe identity


viewInput : Config msg -> String -> ( RuleName, RawRule ) -> Html msg
viewInput props question ( name, rule ) =
    let
        maybeNodeValue =
            Dict.get name props.evaluations
                |> Maybe.map .nodeValue
    in
    case ( ( rule.formule, rule.unite ), maybeNodeValue ) of
        ( ( Just (ChainedMechanism { une_possibilite }), _ ), Just nodeValue ) ->
            case une_possibilite of
                Just { possibilites } ->
                    Components.Select.view
                        { label = question
                        , options = possibilites
                        , onInput = \str -> props.onInput name (NodeValue.Str str) Nothing
                        , toValue = identity
                        , selected = Rules.getStringFromSituation nodeValue
                        , hint = rule.description
                        , toLabel =
                            \pos ->
                                text
                                    (Rules.getOptionTitle
                                        { rules = props.rules
                                        , namespace = Just name
                                        , optionValue = pos
                                        }
                                    )
                        }

                Nothing ->
                    nothing

        ( _, Just ((Boolean _) as nodeValue) ) ->
            Components.Simulateur.BooleanInput.view
                { id = name
                , label = text question
                , current = nodeValue
                , onChecked = \value -> props.onInput name value Nothing
                , hint = rule.description
                }

        ( _, Just value ) ->
            Components.Simulateur.NumericInput.view
                { onInput = props.onInput
                , inputErrors = props.inputErrors
                , situation = props.situation
                , label = text question
                , rule = rule
                , ruleName = name
                , value = value
                }

        _ ->
            nothing
