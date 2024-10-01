module Components.Simulateur.NumericInput exposing (view)

import Components.DSFR.Input as Input
import Core.Format
import Core.InputError as InputError exposing (InputError)
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (Html, text)
import Html.Attributes exposing (placeholder)
import Html.Extra exposing (viewMaybe)
import Maybe.Extra
import Publicodes exposing (Mechanism(..), RawRule)
import Publicodes.Helpers
import Publicodes.NodeValue as NodeValue exposing (NodeValue(..))
import Publicodes.RuleName exposing (RuleName)
import Publicodes.Situation exposing (Situation)


type alias Config msg =
    { onInput : RuleName -> NodeValue -> Maybe InputError -> msg
    , inputErrors : Dict RuleName { msg : String, value : String }
    , situation : Situation
    , label : Html Never
    , rule : RawRule
    , ruleName : RuleName
    , value : NodeValue
    }


view : Config msg -> Html msg
view props =
    let
        defaultConfig =
            { onInput = validationOnInput props
            , label = props.label
            , id = props.ruleName
            , value = ""
            }

        maybeError =
            Dict.get props.ruleName props.inputErrors

        config =
            case ( Dict.get props.ruleName props.situation, props.value, maybeError ) of
                ( Nothing, NodeValue.Number num, Nothing ) ->
                    -- Not touched input (the user didn't fill it)
                    Input.new defaultConfig
                        |> Input.withInputAttrs
                            [ placeholder (Core.Format.withPrecision (Max 2) num) ]

                ( Just _, NodeValue.Number num, Nothing ) ->
                    -- Filled input
                    Input.new { defaultConfig | value = String.fromFloat num }

                ( Just _, NodeValue.Str "", Nothing ) ->
                    -- Empty input (the user filled it and then removed the value)
                    Input.new defaultConfig

                ( _, _, Just error ) ->
                    -- Filled input with invalid value
                    Input.new { defaultConfig | value = error.value }

                _ ->
                    -- Should never happen
                    Input.new defaultConfig
    in
    config
        |> Input.withHint [ viewMaybe text props.rule.description ]
        |> Input.withUnit props.rule.unite
        |> Input.withError
            (maybeError |> Maybe.map (\{ msg } -> [ text msg ]))
        |> Input.view


validationOnInput : Config msg -> String -> msg
validationOnInput props str =
    let
        checkMin num =
            props.rule.plancher
                |> Maybe.andThen Publicodes.Helpers.mechanismToFloat
                |> Maybe.andThen
                    (\min ->
                        if num < min then
                            Just <|
                                props.onInput props.ruleName
                                    (NodeValue.Str str)
                                    (Just
                                        (InputError.InvalidInput
                                            ("Veuillez entrer un nombre supérieur ou égal à " ++ String.fromFloat min)
                                        )
                                    )

                        else
                            Nothing
                    )

        checkMax num =
            -- FIXME: the mechanism need to be evaluated before being used
            props.rule.plafond
                |> Maybe.andThen Publicodes.Helpers.mechanismToFloat
                |> Maybe.andThen
                    (\max ->
                        if num > max then
                            Just <|
                                props.onInput props.ruleName
                                    (NodeValue.Str str)
                                    (Just
                                        (InputError.InvalidInput
                                            ("Veuillez entrer un nombre inférieur ou égal à " ++ String.fromFloat max)
                                        )
                                    )

                        else
                            Nothing
                    )
    in
    -- NOTE: could it be cleaner?
    if String.endsWith "." str then
        props.onInput props.ruleName
            (NodeValue.Str str)
            (Just
                (InputError.InvalidInput
                    ("Veuillez entrer un nombre valide (ex: " ++ String.dropRight 1 str ++ " ou " ++ str ++ "5)")
                )
            )

    else
        case String.toFloat str of
            Just num ->
                Maybe.Extra.or (checkMin num) (checkMax num)
                    |> Maybe.withDefault
                        (props.onInput props.ruleName (NodeValue.Number num) Nothing)

            Nothing ->
                props.onInput props.ruleName
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
