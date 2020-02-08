module GitHub exposing (Token, User, getUserInfo, tokenDecoder, userDecoder)

import Http
import Json.Decode as D exposing (Decoder)


type Token
    = Token String


tokenDecoder : Decoder Token
tokenDecoder =
    D.map Token D.string


type alias User =
    { login : String
    , name : String
    }


userDecoder : Decoder User
userDecoder =
    D.map2 User
        (D.field "login" D.string)
        (D.field "name" D.string)


getUserInfo : (Result Http.Error User -> msg) -> Token -> Cmd msg
getUserInfo msg (Token t) =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("token " ++ t) ]
        , url = "https://api.github.com/user"
        , body = Http.emptyBody
        , expect = Http.expectJson msg userDecoder
        , timeout = Nothing
        , tracker = Nothing
        }
