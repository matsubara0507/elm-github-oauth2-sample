port module Firebase exposing (getSignInResult, signIn, signedIn, signedInWithDecode)

import GitHub
import Json.Decode as D exposing (Decoder)
import Json.Encode as E


decoder : Decoder GitHub.Token
decoder =
    D.map identity
        (D.at [ "credential", "accessToken" ] GitHub.tokenDecoder)


port signIn : () -> Cmd msg


port getSignInResult : () -> Cmd msg


port signedIn : (E.Value -> msg) -> Sub msg


signedInWithDecode : (Result D.Error GitHub.Token -> msg) -> Sub msg
signedInWithDecode msg =
    signedIn (msg << D.decodeValue decoder)
