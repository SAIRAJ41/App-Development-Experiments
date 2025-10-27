import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // -------------------------------------------------------
  // 🔹 FIX 1: Email + Password Sign UP - Returns UserCredential
  // -------------------------------------------------------
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // NOTE: We now return the UserCredential object
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      rethrow;
    }
  }

  // -------------------------------------------------------
  // 1. 📧 signIn (No change needed - assuming LoginPage only awaits completion)
  // -------------------------------------------------------
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.message}');
      rethrow;
    }
  }

  // -------------------------------------------------------
  // 2. 🔑 sendPasswordReset (No change needed)
  // -------------------------------------------------------
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      rethrow;
    }
  }

  // -------------------------------------------------------
  // 3. 🌐 FIX 2: signInWithGoogle - Returns UserCredential
  // -------------------------------------------------------
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google Sign-In was cancelled.");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // NOTE: We now return the UserCredential object
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  // -------------------------------------------------------
  // 4. 👤 FIX 3: guestLogin - Returns UserCredential
  // -------------------------------------------------------
  Future<UserCredential> guestLogin() async {
    try {
      // NOTE: We now return the UserCredential object
      final userCredential = await _auth.signInAnonymously();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Guest login error: ${e.message}');
      rethrow;
    }
  }

  // -------------------------------------------------------
  // 5. 📞 sendOtp (No change needed)
  // -------------------------------------------------------
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verified,
    required Function(FirebaseAuthException) failed,
    required Function(String) codeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-login on Android
        await _auth.signInWithCredential(credential);
        verified(credential);
      },
      verificationFailed: (FirebaseAuthException e) => failed(e),
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('Auto-retrieval timeout. ID: $verificationId');
      },
    );
  }

  // -------------------------------------------------------
  // 6. ✅ verifyOtp (No change needed)
  // -------------------------------------------------------
  Future<void> verifyOtp(String verificationId, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP verification error: ${e.message}');
      rethrow;
    }
  }
}