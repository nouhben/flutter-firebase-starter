import 'package:apple_sign_in/scope.dart';
import 'package:authcodebase/models/custom_user.dart';
import 'package:flutter/material.dart';

abstract class AuthService {
  Stream<CustomUser> get onAuthStateChanged;
  Future<CustomUser> get currentUser;
  //Future<CustomUser> currentUser();
  Future<CustomUser> signInAnon();
  Future<CustomUser> signInWithEmailAndPassword({@required final String email, final String password});
  Future<CustomUser> createUserWithEmailAndPassword({final String email, final String password});
  Future<void> sendResetPasswordEmail({final String email});
  Future<CustomUser> signInWithGoogle();
  Future<CustomUser> signInWithFacebook();
  Future<CustomUser> signInWithApple({List<Scope> scopes});
  Future<void> sendPasswordResetEmail(String email);
  Future<CustomUser> signInWithEmailAndLink({String email, String link});
  Future<bool> isSignInWithEmailLink(String link);
  Future<void> sendSignInWithEmailLink({
    @required String email,
    @required String url,
    @required bool handleCodeInApp,
    @required String iOSBundleID,
    @required String androidPackageName,
    @required bool androidInstallIfNotAvailable,
    @required String androidMinimumVersion,
  });
  Future<void> signOut();
  void dispose();
}
