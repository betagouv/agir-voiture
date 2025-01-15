module Components.SurveyButton exposing (view)

import BetaGouv.DSFR.Button as Button
import BetaGouv.DSFR.Icons as Icons
import Html exposing (Html)


view : Html msg
view =
    Button.new
        { onClick = Nothing
        , label = "Répondre au questionnaire"
        }
        |> Button.linkButton "https://thread-origami-ae6.notion.site/17b576eceac1809d8a42cde05d370068?pvs=105"
        |> Button.rightIcon Icons.system.arrowRightFill
        |> Button.view
