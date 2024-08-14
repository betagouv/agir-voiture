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
import Publicodes.NodeValue as NodeValue
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation exposing (Situation)
import Shared.Model exposing (SimulationStep(..))


type alias Props msg =
    { rules : RawRules
    , situation : Situation
    , evaluations : Dict RuleName Evaluation
    , categories : List UI.Category
    , category : UI.Category
    , onInput : RuleName -> String -> msg
    , questions : List (List RuleName)
    , onNewStep : SimulationStep -> msg
    }


view : Props msg -> Html msg
view props =
    div [ class "flex flex-col mb-6 opacity-100" ]
        [ viewCategoryDescription props.category props.rules
        , div [ class "grid grid-cols-1 gap-6" ]
            (List.map (viewSubQuestions props) props.questions)
        , Components.Simulateur.Navigation.view
            { categories = props.categories
            , onNewStep = props.onNewStep
            , currentStep = Category props.category
            }
        ]


viewCategoryDescription : String -> RawRules -> Html msg
viewCategoryDescription currentCategory rawRules =
    Dict.get currentCategory rawRules
        |> Maybe.andThen .description
        |> viewMaybe
            (\desc ->
                BetaGouv.DSFR.CallOut.callout "" (div [] (Markdown.toHtml Nothing desc))
            )


viewSubQuestions : Props msg -> List RuleName -> Html msg
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


viewQuestion : Props msg -> ( RuleName, RawRule ) -> Bool -> Html msg
viewQuestion props ( name, rule ) isApplicable =
    rule.question
        |> Maybe.map
            (\question ->
                viewInput props question ( name, rule ) isApplicable
            )
        |> viewMaybe identity


viewInput : Props msg -> String -> ( RuleName, RawRule ) -> Bool -> Html msg
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
                        -- TODO: use type alias to get named parameters
                        -- TODO: extract in its own module/component
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

            ( _, Just (NodeValue.Number num) ) ->
                viewNumericInput props question rule name num

            _ ->
                viewDisabledInput props.onInput question name


viewNumericInput : Props msg -> String -> RawRule -> RuleName -> Float -> Html msg
viewNumericInput props question rule name num =
    let
        config =
            { onInput = props.onInput name
            , label = text question
            , id = name
            , value = ""
            }
    in
    (case Dict.get name props.situation of
        Just _ ->
            BetaGouv.DSFR.Input.new { config | value = String.fromFloat num }

        Nothing ->
            BetaGouv.DSFR.Input.new config
                |> BetaGouv.DSFR.Input.withInputAttrs
                    [ placeholder (Core.Format.floatToFrenchLocale (Max 1) num) ]
    )
        |> BetaGouv.DSFR.Input.withHint
            [ viewMaybe text rule.unite
            ]
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
