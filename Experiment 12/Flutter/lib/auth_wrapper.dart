// lib/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/home_page.dart';   // ✅ Your main page after login
import 'pages/login_page.dart';  // ✅ Your login/signup page

/// ✅ AuthWrapper
/// This widget automatically listens to FirebaseAuth's state:
/// - If a user is logged in → navigates to HomePage.
/// - If not logged in → navigates to LoginPage.
/// - It also keeps the user logged in even after closing or minimizing the app.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ While checking Firebase authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ If user is signed in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          debugPrint("✅ Logged in as: ${user.email ?? 'Guest/Phone User'}");
          return const HomePage(); // Go to your main HomePage
        }

        // 🚪 If user is NOT signed in
        debugPrint("🚪 No user session found — redirecting to LoginPage");
        return const LoginPage(); // Go to your login page
      },
    );
  }
}
