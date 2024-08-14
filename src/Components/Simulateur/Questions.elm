module Components.Simulateur.Questions exposing (view)

import BetaGouv.DSFR.CallOut
import BetaGouv.DSFR.Input
import Components.Select
import Components.Simulateur.Navigation
import Core.Format
import Core.Rules as Rules
import Core.UI as UI exposing (Category)
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
import Shared.Model exposing (SimulationStep(..))


type alias Config msg =
    { rules : RawRules
    , situation : Situation
    , evaluations : Dict RuleName Evaluation
    , categories : List UI.Category
    , category : UI.Category
    , onInput : RuleName -> String -> msg
    , questions : List (List RuleName)
    , onNewStep : SimulationStep -> msg
    , inputErrors : Dict RuleName String
    }


view : Config msg -> Html msg
view props =
    div [ class "flex flex-col mb-6 opacity-100" ]
        [ viewCategoryDescription props.category props.rules
        , div [ class "grid grid-cols-1 gap-6" ]
            (List.map (viewSubQuestions props) props.questions)
        , Components.Simulateur.Navigation.view
            { categories = props.categories
            , onNewStep = props.onNewStep
            , currentStep = Category props.category
            , containsErrors = not (Dict.isEmpty props.inputErrors)
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
                            , onInput = props.onInput name
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
        defaultConfig =
            { onInput = props.onInput name
            , label = text question
            , id = name
            , value = ""
            }

        maybeError =
            Dict.get name props.inputErrors
                |> Maybe.map (\err -> [ text err ])

        config =
            case ( Dict.get name props.situation, value ) of
                ( Just _, NodeValue.Number num ) ->
                    -- Filled input
                    BetaGouv.DSFR.Input.new { defaultConfig | value = String.fromFloat num }

                ( Just _, NodeValue.Str "" ) ->
                    -- Empty input (the user filled it and then removed the value)
                    BetaGouv.DSFR.Input.new defaultConfig

                ( Nothing, NodeValue.Number num ) ->
                    -- Not touched input (the user didn't fill it)
                    BetaGouv.DSFR.Input.new defaultConfig
                        |> BetaGouv.DSFR.Input.withInputAttrs
                            [ placeholder (Core.Format.floatToFrenchLocale (Max 1) num) ]

                _ ->
                    -- Should never happen
                    BetaGouv.DSFR.Input.new defaultConfig
    in
    config
        |> BetaGouv.DSFR.Input.withHint [ viewMaybe text rule.unite ]
        |> BetaGouv.DSFR.Input.withError maybeError
        |> BetaGouv.DSFR.Input.numeric
        |> BetaGouv.DSFR.Input.view


viewDisabledInput : (RuleName -> String -> msg) -> String -> RuleName -> Html msg
viewDisabledInput onInput question name =
    BetaGouv.DSFR.Input.new
        { onInput = \_ -> onInput name ""
        , label = text question
        , id = name
        , value = ""
        }
        |> BetaGouv.DSFR.Input.withDisabled True
        |> BetaGouv.DSFR.Input.view
