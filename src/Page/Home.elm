module Page.Home exposing (Model, Msg(..), init, subscriptions, update, view)

{- TODO: use Html.Extra instead of Html -}

import Accessibility.Aria exposing (currentStep)
import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.CallOut as CallOut
import BetaGouv.DSFR.Icons as Icons
import BetaGouv.DSFR.Input as Input
import BetaGouv.DSFR.Tag as Tag
import Dict exposing (Dict)
import Effect
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H exposing (userEmission)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Extra exposing (nothing, viewIfLazy)
import Html.Lazy exposing (lazy, lazy3)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Markdown
import Platform.Cmd as Cmd
import Publicodes as P exposing (Mecanism(..), NodeValue(..))
import Session as S
import UI
import Views.DSFR.Table as Table



-- MODEL


type alias Model =
    { session : S.Data
    , resultRules : List P.RuleName
    , evaluations : Dict P.RuleName P.Evaluation

    -- Represents the current step of the simulation
    , currentStep : SimulationStep

    -- TODO: could be removed?
    , orderedCategories : List UI.Category
    , allCategorieAndSubcategorieNames : List P.RuleName
    , openedCategories : Dict P.RuleName Bool
    }


type SimulationStep
    = Category UI.Category
    | Result
    | Start


emptyModel : Model
emptyModel =
    { session = S.empty
    , evaluations = Dict.empty
    , resultRules = []
    , orderedCategories = []
    , allCategorieAndSubcategorieNames = []
    , currentStep = Start
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
            , currentStep = List.head orderedCategories |> Maybe.map Category |> Maybe.withDefault Start
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
            currentQuestions =
                case model.currentStep of
                    Category category ->
                        Dict.get category session.ui.questions
                            |> Maybe.withDefault []
                            |> List.concat

                    _ ->
                        []
        in
        ( model
        , model.resultRules
            |> List.append currentQuestions
            |> List.append model.orderedCategories
            |> List.append model.allCategorieAndSubcategorieNames
            |> Effect.evaluateAll
        )

    else
        ( model, Cmd.none )



-- UPDATE


type Msg
    = NewAnswer ( P.RuleName, P.NodeValue )
    | NewStep SimulationStep
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

        NewStep step ->
            let
                ( newModel, cmd ) =
                    evaluate { model | currentStep = step }
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
    case Decode.decodeValue P.evaluationDecoder encodedEvaluation of
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

        inQuestions =
            not (model.currentStep == Result)

        gridCols =
            if inQuestions then
                "lg:grid-cols-6"

            else
                "lg:grid-cols-1"
    in
    div []
        [ if Dict.isEmpty model.evaluations then
            div [ class "flex flex-col w-full h-full items-center" ]
                [ div [ class "text-primary my-4" ]
                    [ text "Chargement..."
                    ]
                ]

          else
            div [ class "fr-container md:my-12" ]
                [ div [ class ("flex flex-col lg:grid gap-12 " ++ gridCols) ]
                    [ div [ class "p-4 lg:pl-8 lg:pr-4 lg:col-span-4" ]
                        [ viewIfLazy inQuestions
                            (\() ->
                                viewCategoriesStepper
                                    model.session.rawRules
                                    model.orderedCategories
                                    model.currentStep
                            )
                        , lazy viewCategoryQuestions model
                        ]
                    , if not session.engineInitialized then
                        div [ class "flex flex-col w-full h-full items-center" ]
                            [ div [ class "loading loading-lg text-primary mt-4" ] []
                            ]

                      else if inQuestions then
                        div [ class "flex flex-col p-4 lg:pl-4 lg:col-span-2 lg:pr-8" ]
                            [ div [ class "flex flex-col gap-6 lg:sticky lg:top-4" ]
                                [ lazy viewTotal model

                                -- , lazy viewComparisonTable model
                                ]
                            ]

                      else
                        nothing
                    ]
                ]
        ]



{- TODO: factorize this with the one in UI.elm -}


viewCategoriesStepper : P.RawRules -> List UI.Category -> SimulationStep -> Html Msg
viewCategoriesStepper rules categories currentStep =
    let
        currentTab =
            case currentStep of
                Category category ->
                    category

                _ ->
                    ""

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
            [ case currentStep of
                Start ->
                    text "Démarrer"

                Category _ ->
                    text (Maybe.withDefault "" maybeCurrentTitle)

                Result ->
                    text "Résultat"
            ]
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

            _ ->
                nothing
        ]


viewCategoryQuestions : Model -> Html Msg
viewCategoryQuestions model =
    case model.currentStep of
        Start ->
            nothing

        Category currentCategory ->
            viewCategory model currentCategory

        Result ->
            viewResult model


viewResult : Model -> Html Msg
viewResult model =
    let
        userEmission =
            Dict.get H.userEmission model.evaluations
                |> Maybe.map .nodeValue
    in
    div [ class "" ]
        [ div [ class "flex flex-col gap-8 mb-6 opacity-100" ]
            [ viewCategoriesNavigation model.orderedCategories Result
            , case userEmission of
                Just (P.Num value) ->
                    div []
                        [ h1 []
                            [ text "Résultat" ]
                        , p []
                            [ text "Actuellement, votre voiture vous coûte "
                            , span [ class "font-medium text-[var(--text-title-blue-france)]" ]
                                [ text "650 €" ]
                            , text " par mois et émet "
                            , span [ class "font-medium text-[var(--text-title-blue-france)]" ]
                                [ text (H.formatFloatToFrenchLocale (Max 0) value ++ " kg de CO2e") ]
                            , text " par an."
                            ]
                        , CallOut.callout "L'objectif des 2 tonnes"
                            (div []
                                [ p []
                                    [ text """
                            Pour essayer de maintenir l'augmentation
                            de la température moyenne de la planète en
                            dessous de 2 °C par rapport aux niveaux
                            préindustriels, il faudrait arriver à atteindre la """
                                    , a [ href "https://fr.wikipedia.org/wiki/Neutralit%C3%A9_carbone", target "_blank" ] [ text "neutralité carbone" ]
                                    , text "."
                                    ]
                                , br [] []
                                , p []
                                    [ text "Pour cela, un objectif de 2 tonnes de CO2e par an et par personne a été fixé pour 2050 ("
                                    , a [ href "https://nosgestesclimat.fr/empreinte-climat", target "_blank" ]
                                        [ text "en savoir plus" ]
                                    , text ")."
                                    ]
                                ]
                            )
                        , h2 []
                            [ text "Comparaison avec les différentes alternatives"
                            ]
                        , p []
                            [ text "Pour le même usage de votre voiture, voici une comparaison de ce que cela pourrait donner avec d'autres types de véhicules."
                            ]
                        , case H.getUserEmission model.evaluations of
                            Just userEmissionValue ->
                                viewComparisonTable userEmissionValue model

                            _ ->
                                viewResultError "Une erreur est survenue"
                        , h2 []
                            [ text "Les aides auxquelles vous avez droit"
                            ]
                        , h2 []
                            [ text "Les ressources pour aller plus loin"
                            ]
                        ]

                _ ->
                    viewResultError "Une erreur est survenue"
            ]
        ]


viewCategory : Model -> UI.Category -> Html Msg
viewCategory model category =
    let
        session =
            model.session
    in
    div [ class "" ]
        [ div [ class "flex flex-col mb-6 opacity-100" ]
            [ viewMarkdownCategoryDescription session.rawRules category
            , viewQuestions model (Dict.get category session.ui.questions)
            , viewCategoriesNavigation model.orderedCategories (Category category)
            ]
        ]


viewCategoriesNavigation : List UI.Category -> SimulationStep -> Html Msg
viewCategoriesNavigation orderedCategories step =
    case step of
        Start ->
            nothing

        Category category ->
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
                        Button.new { onClick = Just (NewStep (Category prevCategory)), label = "Retour" }
                            |> Button.leftIcon Icons.system.arrowLeftSFill
                            |> Button.medium
                            |> Button.secondary
                            |> Button.view

                    _ ->
                        div [] []
                , case maybeNextCategory of
                    Just nextCategory ->
                        Button.new { onClick = Just (NewStep (Category nextCategory)), label = "Suivant" }
                            |> Button.rightIcon Icons.system.arrowRightSFill
                            |> Button.medium
                            |> Button.view

                    _ ->
                        Button.new { onClick = Just (NewStep Result), label = "Voir le résultat" }
                            |> Button.rightIcon Icons.system.arrowRightSFill
                            |> Button.medium
                            |> Button.view
                ]

        Result ->
            let
                lastCategory =
                    orderedCategories
                        |> List.reverse
                        |> List.head
                        |> Maybe.withDefault ""
            in
            div [ class "flex justify-between mb-6" ]
                [ Button.new
                    { onClick = Just (NewStep (Category lastCategory))
                    , label = "Retourner aux questions"
                    }
                    |> Button.leftIcon Icons.system.arrowLeftSFill
                    |> Button.medium
                    |> Button.tertiary
                    |> Button.view
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
        viewDisabledInput question name

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
                viewDisabledInput question name


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


viewDisabledInput : String -> P.RuleName -> Html Msg
viewDisabledInput question name =
    Input.new { onInput = \_ -> NoOp, label = text question, id = name, value = "" }
        |> Input.withDisabled True
        |> Input.view


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



-- Results


viewTotal : Model -> Html Msg
viewTotal model =
    let
        userEmission =
            Dict.get H.userEmission model.evaluations
                |> Maybe.map .nodeValue
    in
    div [ class "border p-8 bg-[var(--background-alt-blue-france)]" ]
        (case userEmission of
            Just (P.Num value) ->
                [ h2 [ class "fr-h4" ]
                    [ text "Situation actuelle" ]
                , p [ class "m-0" ]
                    [ text "Votre voiture vous coûte "
                    , span [ class "font-medium text-[var(--text-title-blue-france)]" ]
                        [ text "650 €" ]
                    , text " par mois et émet "
                    , span [ class "font-medium text-[var(--text-title-blue-france)]" ]
                        [ text (H.formatFloatToFrenchLocale (Max 0) value ++ " kg de CO2e") ]
                    , text " par an."
                    ]
                ]

            _ ->
                [ p [ class "fr-error" ]
                    -- TODO: correctly handle errors
                    [ text "Une erreur est survenue" ]
                ]
        )


viewComparisonTable : Float -> Model -> Html Msg
viewComparisonTable userEmission model =
    let
        wrapUserEmission name content =
            if name == H.userEmission then
                span [ class "font-medium italic" ] [ content ]

            else
                content

        getTitle =
            H.getTitle model.session.rawRules

        rows =
            model.resultRules
                |> List.filterMap
                    (\name ->
                        H.getNumValue name model.evaluations
                            |> Maybe.map (\value -> ( name, value ))
                    )
                |> List.sortWith
                    (\( aName, aVal ) ( bName, bVal ) ->
                        if aName == H.userEmission then
                            LT

                        else if bName == H.userEmission then
                            GT

                        else
                            Basics.compare aVal bVal
                    )
                |> List.map
                    (\( name, value ) ->
                        let
                            infos =
                                P.split name
                                    |> List.tail
                                    |> Maybe.withDefault []
                        in
                        case infos of
                            motorisation :: gabarit :: rest ->
                                [ text (getTitle (P.join [ "voiture", "motorisation", motorisation ]))
                                , text (getTitle (P.join [ "voiture", "gabarit", gabarit ]))
                                , case rest of
                                    carburant :: [] ->
                                        text (getTitle (P.join [ "voiture", "thermique", "carburant", carburant ]))

                                    _ ->
                                        text ""
                                , wrapUserEmission name <| text "550 €"
                                , wrapUserEmission name <| viewValuePlusDiff value userEmission "kg"
                                ]

                            _ ->
                                []
                    )
    in
    -- div [ class "border p-8 bg-[var(--background-alt-grey)]" ]
    Table.view
        { caption = Just "Comparaison avec les différentes alternatives"
        , headers =
            [ "Motorisation"
            , "Taille"
            , "Carburant"
            , "Coût mensuel"
            , "Émissions annuelles (CO2eq)"
            ]
        , rows = rows
        }


viewValuePlusDiff : Float -> Float -> String -> Html Msg
viewValuePlusDiff value base unit =
    let
        diff =
            value - base

        tagColor =
            -- less is better
            if diff < 0 then
                "text-[var(--text-default-success)]"

            else
                "text-[var(--text-default-error)]"

        tagPrefix =
            if diff > 0 then
                "+"

            else
                ""

        formattedValue =
            H.formatFloatToFrenchLocale (Max 0) value

        formattedDiff =
            H.formatFloatToFrenchLocale (Max 0) diff
    in
    span [ class "flex gap-2" ]
        [ text (formattedValue ++ " " ++ unit)
        , if diff == 0 then
            nothing

          else
            p [ class ("rounded-full text-xs flex items-center " ++ tagColor) ]
                [ text tagPrefix
                , text formattedDiff
                ]
        ]


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



-- Subscriptions


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.evaluatedRules UpdateAllEvaluation
        , Effect.situationUpdated (\_ -> Evaluate)
        ]
