import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:khung_long/logic_dino/logic_dino.dart';

import 'homepage.dart';
import 'login_page.dart';

class AuthService {
  handleAuthState() {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            return const DinoRunWidget();
          } else {
            return  const LoginPage();
          }
        });
  }

  signInWithGoogle() async {
    final GoogleSignInAccount? googleuser =
        await GoogleSignIn(scopes: <String>["email"]).signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleuser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  signOut() {
    FirebaseAuth.instance.signOut();
  }
}
