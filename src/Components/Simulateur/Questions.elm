module Components.Simulateur.Questions exposing (view)

import BetaGouv.DSFR.CallOut
import BetaGouv.DSFR.Input
import Components.Select
import Components.Simulateur.Navigation
import Core.Format
import Core.InputError as InputError exposing (InputError)
import Core.Rules as Rules
import Core.UI as UI
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (viewMaybe)
import Markdown
import Publicodes exposing (Evaluation, Mecanism(..), RawRule, RawRules)
import Publicodes.NodeValue as NodeValue exposing (NodeValue)
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
    , questions : List (List RuleName)
    , onNewStep : SimulationStep -> msg
    , inputErrors : Dict RuleName { msg : String, value : String }
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
    div [ class "flex flex-col mb-6 opacity-100" ]
        [ viewCategoryDescription props.category props.rules
        , div [ class "grid grid-cols-1 gap-6" ]
            (List.map (viewSubQuestions props) props.questions)
        , Components.Simulateur.Navigation.view
            { categories = props.categories
            , onNewStep = props.onNewStep
            , currentStep = SimulationStep.Category props.category
            , containsErrors = containsErrorsForApplicableQuestions
            }
        ]


viewCategoryDescription : String -> RawRules -> Html msg
viewCategoryDescription currentCategory rawRules =
    div [ class "fr-col-8" ]
        [ Dict.get
            currentCategory
            rawRules
            |> Maybe.andThen .description
            |> viewMaybe
                (\desc ->
                    BetaGouv.DSFR.CallOut.callout ""
                        (div [] (Markdown.toHtml Nothing desc))
                )
        ]


viewSubQuestions : Config msg -> List RuleName -> Html msg
viewSubQuestions props subquestions =
    div [ class "max-w-md flex flex-col gap-3" ]
        (subquestions
            |> List.filterMap
                (\name ->
                    Maybe.map2
                        (\rule eval ->
                            viewQuestion props ( name, rule ) eval.isApplicable
                        )
                        (Dict.get name props.rules)
                        (Dict.get name props.evaluations)
                )
        )


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
                            , options =
                                possibilites
                                    |> List.map
                                        (\possibilite ->
                                            ( possibilite
                                            , Rules.getOptionTitle name possibilite props.rules
                                            )
                                        )
                            , onInput = \str -> props.onInput name (NodeValue.Str str) Nothing
                            , selected = Rules.getStringFromSituation nodeValue
                            }

                    Nothing ->
                        viewDisabledInput props.onInput question name

            ( _, Just value ) ->
                viewNumericInput props question rule name value

            _ ->
                viewDisabledInput props.onInput question name


viewNumericInput : Config msg -> String -> RawRule -> RuleName -> NodeValue -> Html msg
viewNumericInput props question rule name value =
    let
        onNumericInput str =
            -- NOTE: could it be cleaner?
            if String.endsWith "." str then
                props.onInput name
                    (NodeValue.Str str)
                    (Just
                        (InputError.InvalidInput
                            ("Veuillez entrer un nombre valide (ex: " ++ String.dropRight 1 str ++ " ou " ++ str ++ "5)")
                        )
                    )

            else
                case String.toFloat str of
                    Just num ->
                        props.onInput name (NodeValue.Number num) Nothing

                    Nothing ->
                        props.onInput name
                            (NodeValue.Str str)
                            (case str of
                                "" ->
                                    Just InputError.Empty

                                _ ->
                                    Just
                                        (InputError.InvalidInput
                                            "Veuillez entrer un nombre valide (ex: 1234.56)"
                                        )
                            )

        defaultConfig =
            { onInput = onNumericInput
            , label = text question
            , id = name
            , value = ""
            }

        maybeError =
            Dict.get name props.inputErrors

        config =
            case ( Dict.get name props.situation, value, maybeError ) of
                ( Nothing, NodeValue.Number num, Nothing ) ->
                    -- Not touched input (the user didn't fill it)
                    BetaGouv.DSFR.Input.new defaultConfig
                        |> BetaGouv.DSFR.Input.withInputAttrs
                            [ placeholder (Core.Format.floatToFrenchLocale (Max 1) num) ]

                ( Just _, NodeValue.Number num, Nothing ) ->
                    -- Filled input
                    BetaGouv.DSFR.Input.new { defaultConfig | value = String.fromFloat num }

                ( Just _, NodeValue.Str "", Nothing ) ->
                    -- Empty input (the user filled it and then removed the value)
                    BetaGouv.DSFR.Input.new defaultConfig

                ( _, _, Just error ) ->
                    -- Filled input with invalid value
                    BetaGouv.DSFR.Input.new { defaultConfig | value = error.value }

                _ ->
                    -- Should never happen
                    BetaGouv.DSFR.Input.new defaultConfig
    in
    config
        |> BetaGouv.DSFR.Input.withHint [ viewMaybe text rule.unite ]
        |> BetaGouv.DSFR.Input.withError
            (maybeError |> Maybe.map (\{ msg } -> [ text msg ]))
        |> BetaGouv.DSFR.Input.view


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
