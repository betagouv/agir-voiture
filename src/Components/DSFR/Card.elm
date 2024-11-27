module Components.DSFR.Card exposing (CardConfig, Orientation, card, horizontal, linkFull, vertical, view, withArrow, withDescription)

import Accessibility exposing (Attribute, Html, a, decorativeImg, div, h2, p)
import BetaGouv.DSFR.Typography exposing (fr_h4)
import Html.Attributes as Attr exposing (class)
import Html.Attributes.Extra exposing (empty)
import Html.Extra exposing (viewMaybe)


type alias CardConfig msg =
    ( Html msg, Orientation, Options msg )


type alias Options msg =
    { href : Maybe String
    , fullLink : Bool
    , imageSrc : Maybe String
    , description : Maybe (Html msg)
    , details : Maybe (Html msg)
    , arrow : Bool
    , noTitle : Bool
    , extraAttrs : List (Attribute Never)
    }


defaultOptions : Options msg
defaultOptions =
    { href = Nothing
    , fullLink = False
    , imageSrc = Nothing
    , description = Nothing
    , details = Nothing
    , arrow = True
    , noTitle = False
    , extraAttrs = []
    }


type Orientation
    = Horizontal
    | Vertical


linkFull : String -> CardConfig msg -> CardConfig msg
linkFull href ( t, o, options ) =
    ( t, o, { options | href = Just href, fullLink = True } )


withImage : Maybe String -> CardConfig msg -> CardConfig msg
withImage src ( t, o, options ) =
    ( t, o, { options | imageSrc = src } )


withArrow : Bool -> CardConfig msg -> CardConfig msg
withArrow arrow ( t, o, options ) =
    ( t, o, { options | arrow = arrow } )


withDescription : Maybe (Html msg) -> CardConfig msg -> CardConfig msg
withDescription description ( t, o, options ) =
    ( t, o, { options | description = description } )


withDetails : Maybe (Html msg) -> CardConfig msg -> CardConfig msg
withDetails details ( t, o, options ) =
    ( t, o, { options | details = details } )


withNoTitle : CardConfig msg -> CardConfig msg
withNoTitle ( t, o, options ) =
    ( t, o, { options | noTitle = True } )


withExtraAttrs : List (Attribute Never) -> CardConfig msg -> CardConfig msg
withExtraAttrs extraAttrs ( t, o, options ) =
    ( t, o, { options | extraAttrs = extraAttrs } )


vertical : Orientation
vertical =
    Vertical


horizontal : Orientation
horizontal =
    Horizontal


card : Html msg -> Orientation -> CardConfig msg
card title orientation =
    ( title, orientation, defaultOptions )


view : CardConfig msg -> Html msg
view ( title, orientation, { href, fullLink, imageSrc, description, details, arrow, noTitle, extraAttrs } ) =
    let
        orientationClass =
            case orientation of
                Horizontal ->
                    class "fr-card--horizontal"

                Vertical ->
                    class ""

        enlargeClass =
            if fullLink then
                class "fr-enlarge-link"

            else
                empty

        arrowClass =
            if not arrow || href == Nothing then
                class "fr-card--no-arrow fr-card--no-icon"

            else
                empty

        cardTitle =
            href
                |> Maybe.map
                    (\h ->
                        a
                            [ class "fr-card__link", Attr.href h ]
                            [ title ]
                    )
                |> Maybe.withDefault title
    in
    div
        (class "fr-card" :: orientationClass :: enlargeClass :: arrowClass :: extraAttrs)
        [ div
            [ class "fr-card__body" ]
            [ h2
                [ class "fr-card__title"
                , fr_h4
                , if noTitle then
                    class "!m-4"

                  else
                    class ""
                ]
                [ cardTitle ]
            , viewMaybe
                (\desc ->
                    p
                        [ class "fr-card__desc" ]
                        [ desc ]
                )
                description
            , viewMaybe
                (\det ->
                    p
                        [ class "fr-card__detail"
                        ]
                        [ det ]
                )
                details
            ]
        , viewMaybe
            (\src ->
                div
                    [ class "fr-card__img" ]
                    [ decorativeImg
                        [ Attr.src src
                        , class "fr-responsive-img"
                        ]
                    ]
            )
            imageSrc
        ]
