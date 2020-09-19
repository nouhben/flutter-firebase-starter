import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:apple_sign_in/scope.dart';
import 'package:authcodebase/models/custom_user.dart';
import 'package:authcodebase/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CustomUser _userFromFirebase(User user) =>
      user == null ? null : CustomUser(uid: user.uid, email: user.email ?? '', displayName: user.displayName, photoUrl: user.photoURL);

  @override
  Future<CustomUser> get currentUser async {
    return _userFromFirebase(_auth.currentUser);
  }

//  // Determine if Apple SignIn is available
//  Future<bool> get appleSignInAvailable => AppleSignIn.isAvailable();

  @override
  void dispose() {}

  @override
  Stream<CustomUser> get onAuthStateChanged => _auth.authStateChanges().map(_userFromFirebase);

  @override
  Future<void> sendResetPasswordEmail({String email}) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<CustomUser> signInAnon() async {
    final user = await _auth.signInAnonymously();
    return _userFromFirebase(user.user);
  }

  @override
  Future<CustomUser> signInWithEmailAndPassword({String email, String password}) async {
    final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _userFromFirebase(userCredential.user);
  }

  @override
  Future<CustomUser> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount googleUser = await googleSignIn.signIn();

    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final UserCredential userCredential = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: googleAuth.idToken, accessToken: googleAuth.accessToken),
        );
        return _userFromFirebase(userCredential.user);
      } else {
        throw PlatformException(code: 'ERROR_MISSING_GOOGLE_AUTH_TOKEN', message: 'Missing Google Auth Token');
      }
    } else {
      throw PlatformException(code: 'ERROR_ABORTED_BY_USER', message: 'Sign in aborted by user');
    }
  }

  @override
  Future<CustomUser> createUserWithEmailAndPassword({String email, String password}) async {
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return _userFromFirebase(userCredential.user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<bool> isSignInWithEmailLink(String link) async {
    return _auth.isSignInWithEmailLink(link);
  }

  @override
  Future<void> sendSignInWithEmailLink({
    String email,
    String url,
    bool handleCodeInApp,
    String iOSBundleID,
    String androidPackageName,
    bool androidInstallIfNotAvailable,
    String androidMinimumVersion,
  }) async {
    return await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: url,
        handleCodeInApp: handleCodeInApp,
        iOS: {'iOSBundleID': iOSBundleID},
        android: {
          'androidPackageName': androidPackageName,
          'androidMinimumVersion': androidMinimumVersion,
          'androidInstallIfNotAvailable': androidInstallIfNotAvailable,
        },
      ),
    );
  }

  @override
  Future<CustomUser> signInWithApple({List<Scope> scopes = const []}) async {
    // 1. perform the sign-in request
    final AuthorizationResult appleResult = await AppleSignIn.performRequests(
      [
        AppleIdRequest(requestedScopes: scopes),
      ],
    );
    if (appleResult.error != null) {
      //TODO: handle apple errors
      return null;
    }
    // 2. check the result
    switch (appleResult.status) {
      case AuthorizationStatus.authorized:
        final AuthCredential credential = OAuthProvider('apple.com').credential(
          accessToken: String.fromCharCodes(appleResult.credential.authorizationCode),
          idToken: String.fromCharCodes(appleResult.credential.identityToken),
        );
//          final AppleIdCredential appleIdCredential = appleResult.credential;
//          final oAuthProvider = OAuthProvider('apple.com');
//          final credential = oAuthProvider.credential(
//            idToken: String.fromCharCodes(appleIdCredential.identityToken),
//            accessToken: String.fromCharCodes(appleIdCredential.authorizationCode),
//          );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        // Optional, Update user data in Firestore
        if (scopes.contains(Scope.fullName)) {
          final appleIdCredential = appleResult.credential;
          await userCredential.user.updateProfile(
            displayName: '${appleIdCredential.fullName.givenName} ${appleIdCredential.fullName.familyName}',
          );
        }
        return _userFromFirebase(userCredential.user);
      case AuthorizationStatus.error:
        print(appleResult.error.toString());
        throw PlatformException(
          code: 'ERROR_AUTHORIZATION_DENIED',
          message: appleResult.error.toString(),
        );
        break;
      case AuthorizationStatus.cancelled:
        throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
        break;
    }

    return null;
  }

  @override
  Future<CustomUser> signInWithFacebook() async {
    // https://github.com/roughike/flutter_facebook_login/issues/210
    final FacebookLogin facebookLogin = FacebookLogin();
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    final FacebookLoginResult loginResult = await facebookLogin.logIn(<String>['public_profile']);
    if (loginResult.accessToken != null) {
      final UserCredential userCredential = await _auth.signInWithCredential(
        FacebookAuthProvider.credential(
          loginResult.accessToken.token,
        ),
      );
      return _userFromFirebase(userCredential.user);
    } else {
      throw PlatformException(code: 'ERROR_ABORTED_BY_USER', message: 'Sign in aborted by user');
    }
  }

  @override
  Future<CustomUser> signInWithEmailAndLink({String email, String link}) async {
    final UserCredential userCredential = await _auth.signInWithEmailLink(email: email, emailLink: link);
    return _userFromFirebase(userCredential.user);
  }

  @override
  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final FacebookLogin facebookLogin = FacebookLogin();
      await facebookLogin.logOut();
      return _auth.signOut();
    } catch (e) {
      return null;
    }
  }
}
