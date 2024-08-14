module Core.InputError exposing (InputError(..), toMessage)


type InputError
    = Empty
    | InvalidInput String


toMessage : InputError -> String
toMessage error =
    case error of
        Empty ->
            "Ce champ est obligatoire"

        InvalidInput message ->
            message
