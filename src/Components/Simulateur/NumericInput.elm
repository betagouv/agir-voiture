module Components.Simulateur.NumericInput exposing (view)

import BetaGouv.DSFR.Input
import Core.Format
import Core.InputError as InputError exposing (InputError)
import Dict exposing (Dict)
import FormatNumber.Locales exposing (Decimals(..))
import Html exposing (Html, text)
import Html.Attributes exposing (placeholder)
import Html.Extra exposing (viewMaybe)
import Publicodes exposing (Mecanism(..), RawRule)
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
                    BetaGouv.DSFR.Input.new defaultConfig
                        |> BetaGouv.DSFR.Input.withInputAttrs
                            [ placeholder (Core.Format.withPrecision (Max 2) num) ]

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
        |> BetaGouv.DSFR.Input.withHint [ viewMaybe text props.rule.unite ]
        |> BetaGouv.DSFR.Input.withError
            (maybeError |> Maybe.map (\{ msg } -> [ text msg ]))
        |> BetaGouv.DSFR.Input.view


validationOnInput : Config msg -> String -> msg
validationOnInput props str =
    let
        maybeMin =
            props.rule.plancher
                |> Maybe.andThen
                    (\expr ->
                        case expr of
                            Expr (NodeValue.Number num) ->
                                Just num

                            _ ->
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
                maybeMin
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
                    |> Maybe.withDefault (props.onInput props.ruleName (NodeValue.Number num) Nothing)

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
