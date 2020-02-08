module GitHub exposing (Repository, Token, User, getUserInfo, tokenDecoder, userDecoder)

import Http
import Json.Decode as D exposing (Decoder)
import Json.Encode as E


type Token
    = Token String


tokenDecoder : Decoder Token
tokenDecoder =
    D.map Token D.string


type alias User =
    { login : String
    , name : String
    , repos : List Repository
    }


type alias Repository =
    { name : String
    , url : String
    , language : Maybe Language
    , star : Int
    }


type alias Language =
    { name : String
    , color : String
    }


userDecoder : Decoder User
userDecoder =
    D.map3 User
        (D.field "login" D.string)
        (D.field "name" D.string)
        (D.at [ "repositories", "nodes" ] (D.list repoDecoder))


repoDecoder : Decoder Repository
repoDecoder =
    D.map4 Repository
        (D.field "name" D.string)
        (D.field "url" D.string)
        (D.field "primaryLanguage" <| D.nullable languageDecoder)
        (D.at [ "stargazers", "totalCount" ] D.int)


languageDecoder : Decoder Language
languageDecoder =
    D.map2 Language
        (D.field "name" D.string)
        (D.field "color" D.string)


getUserInfo : (Result Http.Error User -> msg) -> Token -> Cmd msg
getUserInfo msg (Token t) =
    let
        query =
            """
    query {
      viewer {
        login
        name
        repositories(first: 100, orderBy: {field: STARGAZERS, direction: DESC}, ownerAffiliations: [OWNER], isFork: false) {
          nodes {
            name
            url
            primaryLanguage {
              name
              color
            }
            stargazers {
              totalCount
            }
          }
        }
      }
    }
    """

        decoder =
            D.map identity (D.at [ "data", "viewer" ] userDecoder)
    in
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("token " ++ t) ]
        , url = "https://api.github.com/graphql"
        , body = Http.jsonBody (E.object [ ( "query", E.string query ) ])
        , expect = Http.expectJson msg decoder
        , timeout = Nothing
        , tracker = Nothing
        }
