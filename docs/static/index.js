'use strict';
const app = Elm.Main.init(
  { node: document.getElementById('main')
  , flags: {}
  }
);

// Your web app's Firebase configuration
var firebaseConfig = {
  apiKey: "AIzaSyAzfrLaNQVpWO63gxO-WADwEpbBu07Py-g",
  authDomain: "elm-github-oauth2-sample.firebaseapp.com",
  databaseURL: "https://elm-github-oauth2-sample.firebaseio.com",
  projectId: "elm-github-oauth2-sample",
  storageBucket: "elm-github-oauth2-sample.appspot.com",
  messagingSenderId: "821061091496",
  appId: "1:821061091496:web:14cda1d173a4a8d5eb029d"
};
// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const provider = new firebase.auth.GithubAuthProvider();

app.ports.signIn.subscribe(_ => {
  firebase.auth().signInWithPopup(provider).then(function(result) {
    console.log(result.user)
    app.ports.signedIn.send(result);
  }).catch(function(error) {
    app.ports.failSignIn.send(error)
  });
});
