module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Firebase
import GitHub
import Html exposing (Html, button, div, text)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Json
import Url exposing (Url)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


type alias Model =
    { token : Maybe GitHub.Token
    , user : Maybe GitHub.User
    , error : Maybe String
    , key : Nav.Key
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | SignIn
    | SignedIn (Result Json.Error GitHub.Token)
    | FailSignIn (Result Json.Error String)
    | FetchUser (Result Http.Error GitHub.User)


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ _ key =
    ( Model Nothing Nothing Nothing key, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        LinkClicked (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged _ ->
            ( model, Cmd.none )

        SignIn ->
            ( model, Firebase.signIn () )

        SignedIn (Ok token) ->
            ( { model | token = Just token, error = Nothing }, GitHub.getUserInfo FetchUser token )

        SignedIn (Err err) ->
            ( { model | error = Just (Json.errorToString err) }, Cmd.none )

        FailSignIn (Ok err) ->
            ( { model | error = Just err }, Cmd.none )

        FailSignIn (Err err) ->
            ( { model | error = Just (Json.errorToString err) }, Cmd.none )

        FetchUser (Ok user) ->
            ( { model | user = Just user, error = Nothing }, Cmd.none )

        FetchUser (Err _) ->
            ( { model | error = Just "fetch github user error" }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "Elm GitHub OAuth 2.0 Sample", body = [ viewBody model ] }


viewBody : Model -> Html Msg
viewBody model =
    Html.div [ Attr.class "position-relative text-center" ]
        [ case model.user of
            Just user ->
                text ("Hi " ++ user.login)

            Nothing ->
                signinButton model
        ]


signinButton : Model -> Html Msg
signinButton _ =
    div [ Attr.class "f3 mt-3" ]
        [ button
            [ Attr.class "btn btn-large btn-outline-blue mr-2"
            , Attr.type_ "button"
            , Event.onClick SignIn
            ]
            [ text "Sign in with GitHub" ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Firebase.signedInWithDecode SignedIn
        , Firebase.failSignInWithDecode FailSignIn
        ]
