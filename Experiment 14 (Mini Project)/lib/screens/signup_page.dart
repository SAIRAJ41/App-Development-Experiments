import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart'; // *** UPDATED PATH ***
import '../services/database_service.dart';

//############################################################################
// SIGN UP SCREEN
//############################################################################

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Create an instance of the AuthService
  final AuthService _auth = AuthService();
  final DatabaseService _dbService = DatabaseService();

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.asset('assets/background_video.mp4')
          ..initialize().then((_) {
            setState(() {});
            _videoController.play();
            _videoController.setLooping(true);
            _videoController.setVolume(0.0);
          });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glowController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _videoController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper to show error messages
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  // Handle Email & Password Sign Up
  void _handleSignUp() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("All fields are required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _auth.signUpWithEmail(name, email, password);

      if (user != null && mounted) {
        // Save user data (name and email) to Firestore database
        try {
          // *** FIX 1: Changed 'name:' to 'displayName:' ***
          await _dbService.updateUserData(
            displayName: name,
            email: email,
          );
        } catch (e) {
          // Log error but don't block signup if Firestore save fails
          debugPrint("Error saving user data to Firestore: $e");
        }

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Sign up successful! Please log in.'),
          ),
        );
        // Go back to the login page
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Sign up failed. Please try again.";
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar("An unexpected error occurred: ${e.toString()}");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Handle Google Sign In
  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      User? user = await _auth.signInWithGoogle();
      if (user != null && mounted) {
        // Save user data from Google to Firestore database
        try {
          // *** FIX 2: Changed 'name:' to 'displayName:' ***
          await _dbService.updateUserData(
            displayName: user.displayName ?? 'Google User',
            email: user.email,
            photoURL: user.photoURL,
          );
        } catch (e) {
          // Log error but don't block sign-in if Firestore save fails
          debugPrint("Error saving Google user data to Firestore: $e");
        }

        // Google Sign In still goes to /home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      _showErrorSnackBar("Google Sign-In failed: ${e.toString()}");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Video Background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          // Glass Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C9FF)
                                    .withOpacity(_glowAnimation.value * 0.7),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: const Color(0xFFE040FB)
                                    .withOpacity(_glowAnimation.value * 0.7),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/login_logo.png',
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create your cosmic identity',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Glass Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          width: screenSize.width * 0.9,
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Welcome to Lunaris',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Name Field
                              TextField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                decoration: _buildInputDecoration(
                                  label: 'Name',
                                  icon: Icons.person_outline,
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _buildInputDecoration(
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: _buildInputDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outlined,
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 24),

                              // "Create Account" Button
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00C9FF),
                                      Color(0xFFE040FB)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C9FF)
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(-5, 5),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFE040FB)
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(5, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'CREATE ACCOUNT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // "OR" Separator
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: Colors.white.withOpacity(0.2))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.5)),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: Colors.white.withOpacity(0.2))),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Google Sign In
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  icon: Text(
                                    'G', // Using 'G' as placeholder for Google logo
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  label: Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "Already have an account?" Text
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 14),
                        children: [
                          const TextSpan(text: "Already have an account? "),
                          TextSpan(
                            text: 'Login',
                            style: const TextStyle(
                              color: Color(0xFF00C9FF),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (!_isLoading) {
                                  Navigator.pop(context);
                                }
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Loading Overlay ---
          // This covers the screen when _isLoading is true
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method for text fields
  InputDecoration _buildInputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0x80FFFFFF)), // Optimized
      prefixIcon:
          Icon(icon, color: const Color(0xB3FFFFFF), size: 20), // Optimized
      filled: true,
      fillColor: const Color(0x0DFFFFFF), // Optimized
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF00C9FF), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }
}