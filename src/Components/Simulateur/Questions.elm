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
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (viewMaybe)
import Markdown
import Publicodes exposing (Evaluation, Mecanism(..), RawRule, RawRules)
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
            |> viewMaybe (\desc -> div [] (Markdown.toHtml Nothing desc))
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
                                div [ class "fr-col-8" ]
                                    [ viewQuestion props ( name, rule ) eval.isApplicable
                                    ]
                            )
                            (Dict.get name props.rules)
                            (Dict.get name props.evaluations)
                    )
            )
        ]


viewQuestion : Config msg -> ( RuleName, RawRule ) -> Bool -> Html msg
viewQuestion props ( name, rule ) isApplicable =
    rule.question
        |> Maybe.map
            (\question ->
                viewInput props question ( name, rule ) isApplicable
            )
        |> viewMaybe identity


viewInput : Config msg -> String -> ( RuleName, RawRule ) -> Bool -> Html msg
viewInput props question ( name, rule ) isApplicable =
    let
        maybeNodeValue =
            Dict.get name props.evaluations
                |> Maybe.map .nodeValue
    in
    if not isApplicable then
        viewDisabledInput props.onInput question name

    else
        case ( ( rule.formule, rule.unite ), maybeNodeValue ) of
            ( ( Just (ChainedMecanism { une_possibilite }), _ ), Just nodeValue ) ->
                case une_possibilite of
                    Just { possibilites } ->
                        Components.Select.view
                            { label = question
                            , options = possibilites
                            , onInput = \str -> props.onInput name (NodeValue.Str str) Nothing
                            , toValue = identity
                            , selected = Rules.getStringFromSituation nodeValue
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
                        viewDisabledInput props.onInput question name

            ( _, Just ((Boolean _) as nodeValue) ) ->
                Components.Simulateur.BooleanInput.view
                    { id = name
                    , label = text question
                    , current = nodeValue
                    , onChecked = \value -> props.onInput name value Nothing
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
                viewDisabledInput props.onInput question name


viewDisabledInput :
    (RuleName -> NodeValue -> Maybe InputError -> msg)
    -> String
    -> RuleName
    -> Html msg
viewDisabledInput onInput question name =
    BetaGouv.DSFR.Input.new
        { onInput = \_ -> onInput name NodeValue.Empty Nothing
        , label = text question
        , id = name
        , value = ""
        }
        |> BetaGouv.DSFR.Input.withDisabled True
        |> BetaGouv.DSFR.Input.view
