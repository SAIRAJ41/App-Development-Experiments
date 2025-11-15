import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Secret suffix to append to passwords
  static const String _passwordSuffix = '##';

  // Helper method to append secret suffix to password
  String _appendPasswordSuffix(String password) {
    return password + _passwordSuffix;
  }

  // Sign in with Email & Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Append secret suffix to password before authentication
      final String modifiedPassword = _appendPasswordSuffix(password);
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: modifiedPassword,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Re-throw the exception to be caught in the UI
      throw e;
    }
  }

  // Sign up with Email & Password
  Future<User?> signUpWithEmail(String name, String email, String password) async {
    try {
      // Append secret suffix to password before creating account
      final String modifiedPassword = _appendPasswordSuffix(password);
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: modifiedPassword,
      );
      User? user = result.user;

      // After creating the user, update their display name
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
        return _auth.currentUser;
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If the user cancelled the flow
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;

    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // *** NEW: Sign in as Guest (Anonymously) ***
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      // Reload user to ensure all properties are up to date
      await result.user?.reload();
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      // Re-throw to be handled in UI
      throw e;
    }
  }


  // Sign out
  Future<void> signOut() async {
    // Check if user is anonymous
    final bool isAnonymous = _auth.currentUser?.isAnonymous ?? false;

    // Always sign out from Firebase
    await _auth.signOut();

    // Only sign out from Google if the user is NOT anonymous
    // Trying to sign out of Google when signed in anonymously
    // can cause issues.
    if (!isAnonymous) {
      // Check if Google user is still signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }
}
