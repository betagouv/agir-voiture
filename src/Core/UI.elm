module Core.UI exposing (..)

{-| This module contains all the types and functions related to the
[`ui.yaml`](https://github.com/betagouv/publicodes-voiture/blob/main/ui.yaml)
file.

The `ui.yaml` file define the list of categories (which represent the
_simulation steps_) and the list of questions to display in the UI.

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Publicodes.RuleName exposing (RuleName)


{-| A category is a classic Publicodes rule. However, it's convenient to be
able to distinguish them from the other rules.
-}
type alias Category =
    RuleName


{-| Information about a category.

The `index` field is used to order the categories in the UI (ascending order).

-}
type alias CategoryInfos =
    { index : Int
    }


decodeCategoryInfos : Decoder CategoryInfos
decodeCategoryInfos =
    Decode.succeed CategoryInfos
        |> required "index" int


{-| Associates for each category its information.
-}
type alias Categories =
    Dict Category CategoryInfos


{-| Associates for each category the list of questions to display.

The questions are grouped by sections. Each section is a list of questions.

-}
type alias Questions =
    Dict Category (List RuleName)


{-| Iso between with the
[`ui.yaml`](https://github.com/betagouv/publicodes-voiture/blob/main/ui.yaml)
file.
-}
type alias Data =
    { categories : Categories
    , questions : Questions
    }


empty : Data
empty =
    { categories = Dict.empty
    , questions = Dict.empty
    }


decode : Decoder Data
decode =
    Decode.succeed Data
        |> required "categories" (dict decodeCategoryInfos)
        |> required "questions" (dict (list string))



-- Helpers


getOrderedCategories : Categories -> List Category
getOrderedCategories categories =
    Dict.toList categories
        |> List.sortBy (\( _, { index } ) -> index)
        |> List.map Tuple.first


getAllCategoryAndSubCategoryNames : Categories -> List Category
getAllCategoryAndSubCategoryNames categories =
    categories
        |> Dict.toList
        |> List.map Tuple.first
