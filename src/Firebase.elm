port module Firebase exposing (failSignIn, failSignInWithDecode, signIn, signedIn, signedInWithDecode)

import GitHub
import Json.Decode as D exposing (Decoder)
import Json.Encode as E


decoder : Decoder GitHub.Token
decoder =
    D.map identity
        (D.at [ "credential", "accessToken" ] GitHub.tokenDecoder)


port signIn : () -> Cmd msg


port signedIn : (E.Value -> msg) -> Sub msg


signedInWithDecode : (Result D.Error GitHub.Token -> msg) -> Sub msg
signedInWithDecode msg =
    signedIn (msg << D.decodeValue decoder)


port failSignIn : (E.Value -> msg) -> Sub msg


failSignInWithDecode : (Result D.Error String -> msg) -> Sub msg
failSignInWithDecode msg =
    failSignIn (msg << D.decodeValue D.string)
