module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Debug
import Firebase
import GitHub
import Html exposing (Html, a, button, div, h3, li, span, text, ul)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Json
import Octicons
import Pie
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
        [ case ( model.error, model.user ) of
            ( Just err, _ ) ->
                text err

            ( _, Just user ) ->
                viewUser user

            _ ->
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


viewUser : GitHub.User -> Html msg
viewUser user =
    let
        total =
            List.map .star user.repos
                |> List.sum
                |> String.fromInt
    in
    div [ Attr.class "container-sm my-3" ]
        [ h3 [ Attr.class "my-2" ]
            [ text (user.login ++ "'s points: " ++ total) ]
        , Pie.view user
        , viewRepositories user
        ]


viewRepositories : GitHub.User -> Html msg
viewRepositories user =
    let
        viewRepository repo =
            li [ Attr.class "Box-row mb-3" ]
                [ div [ Attr.class "float-left" ]
                    [ Octicons.repo Octicons.defaultOptions
                    , a [ Attr.href repo.url, Attr.class "ml-1" ]
                        [ text (user.login ++ "/" ++ repo.name) ]
                    ]
                , div [ Attr.class "float-right" ]
                    [ span [ Attr.class "mr-2" ] <|
                        case repo.language of
                            Nothing ->
                                []

                            Just lang ->
                                [ span
                                    [ Attr.class "circle mr-1"
                                    , Attr.style "background-color" lang.color
                                    , Attr.style "top" "1px"
                                    , Attr.style "position" "relative"
                                    , Attr.style "width" "1em"
                                    , Attr.style "height" "1em"
                                    , Attr.style "display" "inline-block"
                                    ]
                                    []
                                , text lang.name
                                ]
                    , text (String.fromInt repo.star)
                    , Octicons.star Octicons.defaultOptions
                    ]
                ]
    in
    div [ Attr.class "Box" ]
        [ ul [] (List.map viewRepository user.repos)
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Firebase.signedInWithDecode SignedIn
        , Firebase.failSignInWithDecode FailSignIn
        ]
