module Page.Home exposing (Model, Msg(..), init, subscriptions, update, view)

{- TODO: use Html.Extra instead of Html -}

import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.CallOut as CallOut
import BetaGouv.DSFR.Icons as Icons
import BetaGouv.DSFR.Input as Input
import BetaGouv.DSFR.Typography as Typo
import Dict exposing (Dict)
import Effect
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra as Attr
import Html.Events exposing (..)
import Html.Extra exposing (nothing, viewIf)
import Html.Lazy exposing (lazy, lazy3)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Markdown
import Platform.Cmd as Cmd
import Publicodes as P exposing (Mecanism(..), NodeValue(..))
import Session as S
import UI



-- MODEL


type alias Model =
    { session : S.Data
    , resultRules : List P.RuleName
    , evaluations : Dict P.RuleName Evaluation
    , currentTab : Maybe UI.Category

    -- TODO: could be removed?
    , orderedCategories : List UI.Category
    , allCategorieAndSubcategorieNames : List P.RuleName
    , openedCategories : Dict P.RuleName Bool
    }


{-| TODO: should it be moved in Publicodes module?
-}
type alias Evaluation =
    { nodeValue : P.NodeValue
    , isApplicable : Bool
    }


evaluationDecoder : Decode.Decoder Evaluation
evaluationDecoder =
    Decode.succeed Evaluation
        |> Decode.required "nodeValue" P.nodeValueDecoder
        |> Decode.required "isApplicable" Decode.bool


emptyModel : Model
emptyModel =
    { session = S.empty
    , evaluations = Dict.empty
    , resultRules = []
    , orderedCategories = []
    , allCategorieAndSubcategorieNames = []
    , currentTab = Nothing
    , openedCategories = Dict.empty
    }


init : S.Data -> ( Model, Cmd Msg )
init session =
    let
        orderedCategories =
            UI.getOrderedCategories session.ui.categories
    in
    evaluate
        { emptyModel
            | session = session
            , resultRules = H.getResultRules session.rawRules
            , orderedCategories = orderedCategories
            , allCategorieAndSubcategorieNames =
                UI.getAllCategoryAndSubCategoryNames session.ui.categories
            , currentTab = List.head orderedCategories
        }


{-| We try to evaluate only the rules that need to be updated:

  - all the questions and subquestions of the current category
  - all the result rules
  - all the categories (as they are always displayed)
  - all the subcategories if displayed (for now they all are evaluated each time
    the situation changes)

-}
evaluate : Model -> ( Model, Cmd Msg )
evaluate model =
    let
        session =
            model.session
    in
    if session.engineInitialized then
        let
            currentCategory =
                -- NOTE: we always have a currentTab
                Maybe.withDefault "" model.currentTab

            currentCategoryQuestions =
                Dict.get currentCategory session.ui.questions
                    |> Maybe.withDefault []
                    |> List.concat
        in
        ( model
        , model.resultRules
            |> List.append currentCategoryQuestions
            |> List.append model.orderedCategories
            |> List.append model.allCategorieAndSubcategorieNames
            |> Effect.evaluateAll
        )

    else
        ( model, Cmd.none )



-- UPDATE


type Msg
    = NewAnswer ( P.RuleName, P.NodeValue )
    | ChangeTab P.RuleName
    | SetSubCategoryGraphStatus P.RuleName Bool
    | Evaluate
    | UpdateEvaluation ( P.RuleName, Encode.Value )
    | UpdateAllEvaluation (List ( P.RuleName, Encode.Value ))
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewAnswer ( name, value ) ->
            ( S.updateSituation (Dict.insert name value) model
            , Effect.updateSituation ( name, P.nodeValueEncoder value )
            )

        ChangeTab category ->
            let
                ( newModel, cmd ) =
                    evaluate { model | currentTab = Just category }
            in
            ( newModel, Cmd.batch [ Effect.scrollTo ( 0, 0 ), cmd ] )

        SetSubCategoryGraphStatus category status ->
            let
                newOpenedCategories =
                    Dict.insert category status model.openedCategories
            in
            ( { model | openedCategories = newOpenedCategories }, Cmd.none )

        Evaluate ->
            evaluate model

        UpdateEvaluation ( name, encodedEvaluation ) ->
            ( updateEvaluation ( name, encodedEvaluation ) model, Cmd.none )

        UpdateAllEvaluation encodedEvaluations ->
            ( List.foldl updateEvaluation model encodedEvaluations, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


updateEvaluation : ( P.RuleName, Encode.Value ) -> Model -> Model
updateEvaluation ( name, encodedEvaluation ) model =
    case Decode.decodeValue evaluationDecoder encodedEvaluation of
        Ok eval ->
            { model | evaluations = Dict.insert name eval model.evaluations }

        Err e ->
            S.updateError (\_ -> Just (S.DecodeError e)) model



-- VIEW


view : Model -> Html Msg
view model =
    let
        session =
            model.session
    in
    div []
        [ if Dict.isEmpty model.evaluations then
            div [ class "flex flex-col w-full h-full items-center" ]
                [ div [ class "loading loading-lg text-primary my-4" ] []
                ]

          else
            div [ class "fr-container md:my-16" ]
                [ div
                    [ class "flex flex-col-reverse lg:grid lg:grid-cols-3" ]
                    [ div [ class "p-4 lg:pl-8 lg:pr-4 lg:col-span-2" ]
                        [ lazy3 viewCategoriesStepper model.session.rawRules model.orderedCategories model.currentTab
                        , lazy viewCategoryQuestions model
                        ]
                    , if not session.engineInitialized then
                        div [ class "flex flex-col w-full h-full items-center" ]
                            [ div [ class "loading loading-lg text-primary mt-4" ] []
                            ]

                      else
                        div [ class "flex flex-col p-4 lg:pl-4 lg:col-span-1 lg:pr-8" ]
                            [ div [ class "lg:sticky lg:top-4" ]
                                [ lazy viewTotal model
                                , lazy viewResults model
                                ]
                            ]
                    ]
                ]
        ]



{- TODO: factorize this with the one in UI.elm -}


viewCategoriesStepper : P.RawRules -> List UI.Category -> Maybe UI.Category -> Html Msg
viewCategoriesStepper rules categories maybeCurrentTab =
    let
        currentTab =
            Maybe.withDefault (List.head categories |> Maybe.withDefault "") maybeCurrentTab

        ( nextIndex, maybeCurrentTitle, maybeNextTitle ) =
            categories
                |> List.foldl
                    (\category ( idx, currentTitle, nextTitle ) ->
                        if category == currentTab then
                            ( idx + 1, Just (H.getTitle rules category), nextTitle )

                        else
                            case ( currentTitle, nextTitle ) of
                                ( Just _, Nothing ) ->
                                    ( idx, currentTitle, Just (H.getTitle rules category) )

                                ( Nothing, Nothing ) ->
                                    ( idx + 1, currentTitle, nextTitle )

                                _ ->
                                    ( idx, currentTitle, nextTitle )
                    )
                    ( 0, Nothing, Nothing )

        currentNumStep =
            String.fromInt nextIndex

        totalNumStep =
            String.fromInt (List.length categories)
    in
    div [ class "fr-stepper" ]
        [ h2 [ class "fr-stepper__title" ]
            [ text (Maybe.withDefault "" maybeCurrentTitle) ]
        , span [ class "fr-stepper__state" ]
            [ text (String.join " " [ "Étape", currentNumStep, "sur", totalNumStep ])
            ]
        , div
            [ class "fr-stepper__steps"
            , attribute "data-fr-current-step" currentNumStep
            , attribute "data-fr-steps" totalNumStep
            ]
            []
        , case maybeNextTitle of
            Just title ->
                p [ class "fr-stepper__details" ]
                    [ span [ class "fr-text--bold" ] [ text "Étape suivante : " ]
                    , text title
                    ]

            Nothing ->
                nothing
        ]


viewCategoryQuestions : Model -> Html Msg
viewCategoryQuestions model =
    let
        session =
            model.session

        currentCategory =
            Maybe.withDefault "" model.currentTab
    in
    div [ class "" ]
        (session.ui.categories
            |> Dict.toList
            |> List.map
                (\( category, _ ) ->
                    let
                        isVisible =
                            currentCategory == category
                    in
                    div
                        [ class
                            ("flex flex-col"
                                ++ (if isVisible then
                                        " mb-6 opacity-100"

                                    else
                                        " opacity-50"
                                   )
                            )
                        ]
                        (if isVisible then
                            [ viewMarkdownCategoryDescription session.rawRules category
                            , viewQuestions model (Dict.get category session.ui.questions)
                            , viewCategoriesNavigation model.orderedCategories category
                            ]

                         else
                            []
                        )
                )
        )


viewCategoriesNavigation : List UI.Category -> String -> Html Msg
viewCategoriesNavigation orderedCategories category =
    let
        nextList =
            H.dropUntilNext ((==) category) ("empty" :: orderedCategories)

        maybePrevCategory =
            if List.head nextList == Just "empty" then
                Nothing

            else
                List.head nextList

        maybeNextCategory =
            nextList
                |> List.drop 2
                |> List.head
    in
    div [ class "flex justify-between mt-6" ]
        [ case maybePrevCategory of
            Just prevCategory ->
                Button.new { onClick = Just (ChangeTab prevCategory), label = "Retour" }
                    |> Button.leftIcon Icons.system.arrowLeftSFill
                    |> Button.medium
                    |> Button.secondary
                    |> Button.view

            _ ->
                div [] []
        , case maybeNextCategory of
            Just nextCategory ->
                Button.new { onClick = Just (ChangeTab nextCategory), label = "Suivant" }
                    |> Button.rightIcon Icons.system.arrowRightSFill
                    |> Button.medium
                    |> Button.view

            _ ->
                div [] []
        ]


viewMarkdownCategoryDescription : P.RawRules -> String -> Html Msg
viewMarkdownCategoryDescription rawRules currentCategory =
    let
        categoryDescription =
            Dict.get currentCategory rawRules
                |> Maybe.andThen (\ruleCategory -> ruleCategory.description)
    in
    case categoryDescription of
        Nothing ->
            text ""

        Just desc ->
            CallOut.callout ""
                (div []
                    (Markdown.toHtml Nothing desc)
                )


viewQuestions : Model -> Maybe (List (List P.RuleName)) -> Html Msg
viewQuestions model maybeQuestions =
    case maybeQuestions of
        Just questions ->
            div [ class "grid grid-cols-1 gap-6" ]
                (List.map (viewSubQuestions model) questions)

        Nothing ->
            text ""


viewSubQuestions : Model -> List P.RuleName -> Html Msg
viewSubQuestions model subquestions =
    div [ class "max-w-md flex flex-col gap-3" ]
        (subquestions
            |> List.map
                (\name ->
                    case ( Dict.get name model.session.rawRules, Dict.get name model.evaluations ) of
                        ( Just rule, Just eval ) ->
                            viewQuestion model ( name, rule ) eval.isApplicable

                        _ ->
                            text ""
                )
        )


viewQuestion : Model -> ( P.RuleName, P.RawRule ) -> Bool -> Html Msg
viewQuestion model ( name, rule ) isApplicable =
    rule.question
        |> Maybe.map
            (\question ->
                viewInput model question ( name, rule ) isApplicable
            )
        |> Maybe.withDefault (text "")


viewInput : Model -> String -> ( P.RuleName, P.RawRule ) -> Bool -> Html Msg
viewInput model question ( name, rule ) isApplicable =
    let
        newAnswer val =
            case String.toFloat val of
                Just value ->
                    NewAnswer ( name, P.Num value )

                Nothing ->
                    if String.isEmpty val then
                        -- FIXME: there is a little delay when updatin an empty input
                        NoOp

                    else
                        NewAnswer ( name, P.Str val )

        maybeNodeValue =
            Dict.get name model.evaluations
                |> Maybe.map .nodeValue
    in
    if not isApplicable then
        viewDisabledInput

    else
        case ( ( rule.formula, rule.unit ), maybeNodeValue ) of
            ( ( Just (UnePossibilite { possibilites }), _ ), Just nodeValue ) ->
                viewSelectInput question model.session.rawRules name possibilites nodeValue

            ( ( _, Just "%" ), Just (P.Num num) ) ->
                viewRangeInput newAnswer num

            ( _, Just (P.Num num) ) ->
                viewNumericInput newAnswer model.session.situation question rule name num

            ( _, Just (P.Boolean bool) ) ->
                viewBooleanRadioInput name bool

            _ ->
                viewDisabledInput


viewNumericInput : (String -> Msg) -> P.Situation -> String -> P.RawRule -> P.RuleName -> Float -> Html Msg
viewNumericInput onInput situation question rule name num =
    let
        config =
            { onInput = onInput
            , label = text question
            , id = name
            , value = ""
            }
    in
    (case Dict.get name situation of
        Just _ ->
            Input.new { config | value = String.fromFloat num }

        Nothing ->
            Input.new config
                |> Input.withInputAttrs
                    [ placeholder (H.formatFloatToFrenchLocale (Max 1) num) ]
    )
        |> Input.withHint [ text (Maybe.withDefault "" rule.unit) ]
        |> Input.numeric
        |> Input.view


{-| TODO: extract this in a clean component in elm-dsfr
-}
viewSelectInput : String -> P.RawRules -> P.RuleName -> List String -> P.NodeValue -> Html Msg
viewSelectInput question rules ruleName possibilites nodeValue =
    div [ class "fr-select-group" ]
        [ Html.label [ class "fr-label", for "select" ]
            [ text question ]
        , select
            [ onInput (\v -> NewAnswer ( ruleName, P.Str v ))
            , class "fr-select"
            , id "select"
            , name "select"
            ]
            (possibilites
                |> List.map
                    (\possibilite ->
                        option
                            [ value possibilite
                            , selected (H.getStringFromSituation nodeValue == possibilite)
                            ]
                            [ text (H.getOptionTitle rules ruleName possibilite) ]
                    )
            )
        ]


viewBooleanRadioInput : P.RuleName -> Bool -> Html Msg
viewBooleanRadioInput name bool =
    div [ class "form-control" ]
        [ label [ class "label cursor-pointer" ]
            [ span [ class "label-text" ] [ text "Oui" ]
            , input
                [ class "radio radio-sm"
                , type_ "radio"
                , checked bool
                , onCheck (\b -> NewAnswer ( name, P.Boolean b ))
                ]
                []
            ]
        , label [ class "label cursor-pointer" ]
            [ span [ class "label-text" ] [ text "Non" ]
            , input
                [ class "radio radio-sm"
                , type_ "radio"
                , checked (not bool)
                , onCheck (\b -> NewAnswer ( name, P.Boolean (not b) ))
                ]
                []
            ]
        ]


viewRangeInput : (String -> Msg) -> Float -> Html Msg
viewRangeInput newAnswer num =
    div [ class "flex flex-row" ]
        [ input
            [ type_ "range"
            , class "range range-accent range-xs my-2"
            , value (String.fromFloat num)
            , onInput newAnswer
            , Html.Attributes.min "0"
            , Html.Attributes.max "100"

            -- Should use `plancher` and `plafond` attributes
            ]
            []
        , span
            [ class "ml-4" ]
            [ text (String.fromFloat num) ]
        ]


viewDisabledInput : Html Msg
viewDisabledInput =
    input [ class "input blur-sm", disabled True ] []



-- Results


viewTotal : Model -> Html Msg
viewTotal model =
    div []
        (H.totalRuleNames
            |> List.map (\name -> viewResult model name)
        )


viewResults : Model -> Html Msg
viewResults model =
    div [ class "stats stats-vertical border w-full rounded-md bg-neutral border-base-200" ]
        (model.resultRules
            |> List.map
                (\name ->
                    if List.any ((==) name) H.totalRuleNames then
                        text ""

                    else
                        viewResult model name
                )
        )


viewResultError : String -> Html Msg
viewResultError title =
    div [ class "stat" ]
        [ div [ class "stat-title" ]
            [ text title ]
        , div [ class "flex items-baseline" ]
            [ div [ class "stat-desc text-error text-xl ml-2" ]
                [ text "une erreur est survenue" ]
            ]
        ]


viewResult : Model -> P.RuleName -> Html Msg
viewResult model name =
    let
        unit =
            H.getUnit model.session.rawRules name

        title =
            H.getTitle model.session.rawRules name
    in
    case Dict.get name model.evaluations of
        Just { nodeValue } ->
            case nodeValue of
                P.Num value ->
                    div
                        [ class "stat" ]
                        [ div [ class "stat-title" ]
                            [ text title ]
                        , div [ class "flex items-baseline" ]
                            [ div [ class "stat-value text-primary" ]
                                [ text
                                    (H.formatFloatToFrenchLocale (Max 0) value)
                                ]
                            , div [ class "stat-desc text-primary ml-2 text-lg font-semibold" ]
                                [ case unit of
                                    Just u ->
                                        text u

                                    _ ->
                                        text ""
                                ]
                            ]
                        ]

                _ ->
                    viewResultError title

        _ ->
            viewResultError title


viewUnit : P.RawRule -> Html Msg
viewUnit rawRule =
    case rawRule.unit of
        Just "l" ->
            text " litre"

        Just unit ->
            text (" " ++ unit)

        Nothing ->
            text ""


viewComparison : Model -> Html Msg
viewComparison model =
    div [ class "bg-neutral border border-base-200 rounded-md p-4" ]
        [ p [ class "text-lg font-semibold" ]
            [ text "Comparaison avec les différentes alternatives" ]
        , viewComparisonTable model
        ]


viewComparisonTable : Model -> Html Msg
viewComparisonTable model =
    Html.ul []
        (model.resultRules
            |> List.map
                (\name ->
                    viewResult model name
                )
        )



-- Subscriptions


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.evaluatedRules UpdateAllEvaluation
        , Effect.situationUpdated (\_ -> Evaluate)
        ]
