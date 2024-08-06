module Page.Simulateur exposing (Model, Msg(..), init, path, subscriptions, update, view)

{- TODO: use Html.Extra instead of Html -}

import Accessibility.Aria exposing (currentStep)
import BetaGouv.DSFR.Button as ButtonDSFR
import BetaGouv.DSFR.CallOut as CallOutDSFR
import BetaGouv.DSFR.Icons as IconsDSFR
import BetaGouv.DSFR.Input as InputDSFR
import Components.ComparisonTable
import Components.DSFR.Card as CardDSFR
import Components.Total
import Dict exposing (Dict)
import Effect
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H exposing (userCost, userEmission)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Extra exposing (nothing, viewIfLazy)
import Html.Lazy exposing (lazy)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import List.Extra exposing (unique)
import Markdown
import Platform.Cmd as Cmd
import Publicodes as P exposing (Mecanism(..), NodeValue(..))
import Session as S exposing (SimulationStep(..))
import UI


path : List String
path =
    [ "simulateur" ]



-- MODEL


type alias Model =
    { session : S.Data
    , resultRules : List P.RuleName
    , evaluations : Dict P.RuleName P.Evaluation

    -- TODO: could be removed?
    , orderedCategories : List UI.Category
    , openedCategories : Dict P.RuleName Bool
    }


emptyModel : Model
emptyModel =
    { session = S.empty
    , evaluations = Dict.empty
    , resultRules = []
    , orderedCategories = []
    , openedCategories = Dict.empty
    }


init : S.Data -> ( Model, Cmd Msg )
init session =
    let
        orderedCategories =
            UI.getOrderedCategories session.ui.categories

        currentStep =
            case session.simulationStep of
                Start ->
                    List.head orderedCategories
                        |> Maybe.map Category
                        |> Maybe.withDefault Start

                _ ->
                    session.simulationStep

        ( newModel, newCmd ) =
            evaluate
                { emptyModel
                    | session = session
                    , resultRules = H.getResultRules session.rawRules
                    , orderedCategories = orderedCategories
                }
    in
    ( newModel, Cmd.batch [ newCmd, H.performCmdNow (NewStep currentStep) ] )


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
                case model.session.simulationStep of
                    Category category ->
                        Dict.get category session.ui.questions
                            |> Maybe.withDefault []
                            |> List.concat

                    _ ->
                        []
        in
        ( model
        , if model.session.simulationStep == Result then
            Effect.evaluateAll model.resultRules

          else
            [ H.userCost, H.userEmission ]
                ++ currentQuestions
                ++ model.orderedCategories
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
                    evaluate (S.updateCurrentStep step model)
            in
            ( newModel
            , Cmd.batch
                [ Effect.scrollTo ( 0, 0 )
                , Effect.saveCurrentStep (S.simulationStepEncoder step)
                , cmd
                ]
            )

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
            case session.simulationStep of
                Category _ ->
                    True

                _ ->
                    False

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
                    [ -- NOTE: the loading is to fast to show a message
                      -- text "Chargement..."
                      nothing
                    ]
                ]

          else
            div [ class "fr-container md:my-8" ]
                [ div [ class ("flex flex-col lg:grid gap-12 " ++ gridCols) ]
                    [ div [ class "p-4 lg:pl-8 lg:pr-4 lg:col-span-4" ]
                        [ viewIfLazy inQuestions
                            (\() ->
                                viewCategoriesStepper
                                    model.session.rawRules
                                    model.orderedCategories
                                    model.session.simulationStep
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
                                [ viewInQuestionsTotal model.evaluations

                                -- , lazy viewComparisonTable model
                                ]
                            ]

                      else
                        nothing
                    ]
                ]
        ]



{- TODO: factorize this with the one in UI.elm -}


viewCategoryQuestions : Model -> Html Msg
viewCategoryQuestions model =
    case model.session.simulationStep of
        Start ->
            viewStart model

        Category currentCategory ->
            viewCategory model currentCategory

        Result ->
            viewResult model


viewStart : Model -> Html Msg
viewStart model =
    div [ class "fr-container bg-[var(--background-default-grey)] md:py-8" ]
        [ div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
            [ div [ class "fr-col-lg-6" ]
                [ h1 [] [ text "Comparer les coûts et les émissions de votre voiture" ]
                , div [ class "fr-text--lead" ]
                    [ text """
                    En répondant à quelques questions, vous pourrez comparer
                    les coûts et les émissions de votre voiture avec d'autres
                    types de véhicules.
                    """
                    ]
                ]
            , img
                [ src "/undraw_order_a_car.svg"
                , alt "Illustration d'une voiture"
                , class "fr-col-lg-4 p-12"
                ]
                []
            ]
        ]


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


viewResult : Model -> Html Msg
viewResult model =
    let
        { userEmission, userCost } =
            H.getUserValues model.evaluations

        rulesToCompare =
            model.resultRules
                |> List.filterMap
                    (\name ->
                        case P.split name of
                            namespace :: rest ->
                                if List.member namespace H.resultNamespaces then
                                    Just rest

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )
                |> unique

        viewCard ( title, link, desc ) =
            CardDSFR.card
                (text title)
                CardDSFR.vertical
                |> CardDSFR.linkFull link
                |> CardDSFR.withDescription
                    (Just
                        (text desc)
                    )
                |> CardDSFR.withArrow True
                |> CardDSFR.view
    in
    div [ class "" ]
        [ div [ class "flex flex-col gap-8 mb-6 opacity-100" ]
            [ viewCategoriesNavigation model.orderedCategories Result
            , div [ class "flex flex-col gap-8" ]
                [ h1 []
                    [ text "Résultat" ]
                , section []
                    [ Components.Total.viewParagraph
                        { cost = userCost, emission = userEmission }
                    , CallOutDSFR.callout "L'objectif des 2 tonnes"
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
                    ]
                , section []
                    [ h2 []
                        [ text "Comparaison avec les différentes alternatives"
                        ]
                    , p []
                        [ text "Pour le même usage de votre voiture, voici une comparaison de ce que cela pourrait donner avec d'autres types de véhicules."
                        ]
                    , case ( userEmission, userCost ) of
                        ( Just emission, Just cost ) ->
                            Components.ComparisonTable.view
                                { rawRules = model.session.rawRules
                                , evaluations = model.evaluations
                                , rulesToCompare = rulesToCompare
                                , userEmission = emission
                                , userCost = cost
                                }

                        _ ->
                            text "No user emission or cost"
                    ]
                , section []
                    [ h2 [] [ text "Les aides financières" ]
                    , p []
                        [ text """
                            Afin d'aider les particuliers à passer à des véhicules plus propres, il existe des aides financières
                            mis en place par l'État et les collectivités locales."""
                        ]
                    , CallOutDSFR.callout ""
                        (span []
                            [ text "Au niveau national par exemple, avec le "
                            , a [ href "https://www.economie.gouv.fr/particuliers/bonus-ecologique", target "_blank" ]
                                [ text "bonus écologique" ]
                            , text ", vous pouvez bénéficier d'une aide allant jusqu'à "
                            , span [ class "text-[var(--text-default-info)]" ] [ text "7 000 €" ]
                            , text " pour l'achat d'un véhicule électrique. Et avec la "
                            , a [ href "https://www.service-public.fr/particuliers/vosdroits/F36848", target "_blank" ]
                                [ text "prime à la conversion" ]
                            , text ", vous pouvez bénéficier d'une aide allant jusqu'à "
                            , span [ class "text-[var(--text-default-info)]" ] [ text "3 000 €" ]
                            , text "."
                            ]
                        )
                    , p []
                        [ text "Il existe également des aides locales auxquelles vous pouvez être éligible."
                        ]
                    , ButtonDSFR.new
                        { onClick = Nothing
                        , label = "Découvrir toutes les aides"
                        }
                        |> ButtonDSFR.linkButton "https://agir.beta.gouv.fr"
                        |> ButtonDSFR.rightIcon IconsDSFR.system.arrowRightFill
                        |> ButtonDSFR.view
                    ]
                , section [ class "mt-8" ]
                    [ h2 []
                        [ text "Les ressources pour aller plus loin"
                        ]
                    , p [] [ text "Découvrez une sélection pour continuer votre engagement." ]
                    , div [ class "fr-grid-row fr-grid-row--gutters fr-grid-row--center" ]
                        ([ ( "Agir !"
                           , "https://agir.beta.gouv.fr"
                           , "Faite vous accompagner pour réduire votre empreinte carbone à travers des actions concrètes."
                           )
                         , ( "Nos Gestes Climat"
                           , "https://nosgestesclimat.fr"
                           , "Calculez votre empreinte carbone individuelle et découvrez des gestes pour la réduire."
                           )
                         , ( "Impact CO2"
                           , "https://impactCO2.fr"
                           , "Comprendre les ordres de grandeur et les équivalences des émissions de CO2e."
                           )
                         , ( "La voiture électrique, solution idéale pour le climat ?"
                           , "https://bonpote.com/la-voiture-electrique-solution-ideale-pour-le-climat"
                           , "Article du chercheur Aurélien Bigo qui décortique les différentes critiques faites à la voiture électrique."
                           )
                         ]
                            |> List.map viewCard
                            |> List.map (\card -> div [ class "fr-col-md-4" ] [ card ])
                        )
                    ]
                ]
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
                        ButtonDSFR.new { onClick = Just (NewStep (Category prevCategory)), label = "Retour" }
                            |> ButtonDSFR.leftIcon IconsDSFR.system.arrowLeftSFill
                            |> ButtonDSFR.medium
                            |> ButtonDSFR.secondary
                            |> ButtonDSFR.view

                    _ ->
                        div [] []
                , case maybeNextCategory of
                    Just nextCategory ->
                        ButtonDSFR.new { onClick = Just (NewStep (Category nextCategory)), label = "Suivant" }
                            |> ButtonDSFR.rightIcon IconsDSFR.system.arrowRightSFill
                            |> ButtonDSFR.medium
                            |> ButtonDSFR.view

                    _ ->
                        ButtonDSFR.new { onClick = Just (NewStep Result), label = "Voir le résultat" }
                            |> ButtonDSFR.rightIcon IconsDSFR.system.arrowRightSFill
                            |> ButtonDSFR.medium
                            |> ButtonDSFR.view
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
                [ ButtonDSFR.new
                    { onClick = Just (NewStep (Category lastCategory))
                    , label = "Retourner aux questions"
                    }
                    |> ButtonDSFR.leftIcon IconsDSFR.system.arrowLeftSFill
                    |> ButtonDSFR.medium
                    |> ButtonDSFR.tertiary
                    |> ButtonDSFR.view
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
            CallOutDSFR.callout ""
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
                    NewAnswer ( name, P.Number value )

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
        case ( ( rule.formule, rule.unite ), maybeNodeValue ) of
            ( ( Just (ChainedMecanism { une_possibilite }), _ ), Just nodeValue ) ->
                case une_possibilite of
                    Just { possibilites } ->
                        -- TODO: use type alias to get named parameters
                        -- TODO: extract in its own module/component
                        viewSelectInput
                            question
                            model.session.rawRules
                            name
                            possibilites
                            nodeValue

                    Nothing ->
                        viewDisabledInput question name

            ( ( _, Just "%" ), Just (P.Number num) ) ->
                viewRangeInput newAnswer num

            ( _, Just (P.Number num) ) ->
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
            InputDSFR.new { config | value = String.fromFloat num }

        Nothing ->
            InputDSFR.new config
                |> InputDSFR.withInputAttrs
                    [ placeholder (H.formatFloatToFrenchLocale (Max 1) num) ]
    )
        |> InputDSFR.withHint [ text (Maybe.withDefault "" rule.unite) ]
        |> InputDSFR.numeric
        |> InputDSFR.view


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
    InputDSFR.new { onInput = \_ -> NoOp, label = text question, id = name, value = "" }
        |> InputDSFR.withDisabled True
        |> InputDSFR.view


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


viewInQuestionsTotal : Dict P.RuleName P.Evaluation -> Html Msg
viewInQuestionsTotal evaluations =
    let
        { userEmission, userCost } =
            H.getUserValues evaluations
    in
    div [ class "border px-6 pt-6 bg-[var(--background-alt-blue-france)]" ]
        [ Components.Total.viewParagraph
            { emission = userEmission, cost = userCost }
        ]



-- Subscriptions


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.evaluatedRules UpdateAllEvaluation
        , Effect.situationUpdated (\_ -> Evaluate)
        ]
