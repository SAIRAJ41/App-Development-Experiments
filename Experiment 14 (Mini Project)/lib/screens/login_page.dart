import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart'; // *** UPDATED PATH ***
import '../services/database_service.dart';
import 'main_navigation.dart';

//############################################################################
// LOGIN SCREEN (Layout Updated)
//############################################################################

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper to show error messages
  void _showErrorSnackBar(String message) {
    if (!mounted) return; // Check if the widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  // Handle Email & Password Login
  void _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Email and Password cannot be empty.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _auth.signInWithEmail(email, password);
      if (user != null && mounted) {
        // Wait a moment for auth state to update, then navigate
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && FirebaseAuth.instance.currentUser != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please check your email and password.';
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
          // *** THIS IS THE FIX ***
          // Changed 'name:' to 'displayName:'
          await _dbService.updateUserData(
            displayName: user.displayName ?? 'Google User',
            email: user.email,
            photoURL: user.photoURL,
          );
          // *** END OF FIX ***

        } catch (e) {
          // Log error but don't block sign-in if Firestore save fails
          debugPrint("Error saving Google user data to Firestore: $e");
        }

        // Wait a moment for auth state to update, then navigate
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && FirebaseAuth.instance.currentUser != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar("Google Sign-In failed: ${e.toString()}");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // *** NEW: Handle Guest Sign In ***
  void _handleGuestSignIn() async {
    setState(() => _isLoading = true);
    try {
      User? user = await _auth.signInAnonymously();
      if (user != null && mounted) {
        // Wait a moment for auth state to update, then navigate
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && FirebaseAuth.instance.currentUser != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      } else if (mounted) {
        _showErrorSnackBar("Guest sign-in failed. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      String message = "Guest Sign-In failed. Please try again.";
      if (e.code == 'operation-not-allowed') {
        message =
            'Anonymous authentication is not enabled. Please contact support.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your connection.';
      }
      if (mounted) {
        _showErrorSnackBar(message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Guest Sign-In failed: ${e.toString()}");
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Handle Forgot Password
  void _handleForgotPassword() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      // Show dialog to enter email
      showDialog(
        context: context,
        builder: (context) {
          final TextEditingController emailController = TextEditingController();
          return AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.9),
            title: Text(
              'Reset Password',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFF00C9FF)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    _showErrorSnackBar("Please enter your email address.");
                    return;
                  }
                  Navigator.pop(context);
                  await _sendPasswordReset(email);
                },
                child: const Text(
                  'Send',
                  style: TextStyle(
                    color: Color(0xFF00C9FF),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Use email from the field
      await _sendPasswordReset(email);
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Password reset email sent! Check your inbox.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Failed to send reset email. Please try again.";
      if (e.code == 'user-not-found') {
        message = 'No account found for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar("An error occurred: ${e.toString()}");
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

          // *** MODIFIED LAYOUT START ***
          // Added SafeArea and Column structure to match SignUpScreen
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column( // This Column now wraps Logo + Glass Card
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Logo Section (Moved Outside) ---
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
                        height: 80, // Kept original login logo size
                      ),
                    ),
                    const SizedBox(height: 24), // Spacing after logo

                    // --- Glass Card ---
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
                              // Logo was here, but is now removed.

                              // Welcome Text (now first item in the box)
                              const Text(
                                'Welcome Back to Lunaris',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your credentials to continue your journey',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 32),

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
                              const SizedBox(height: 8),
                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _isLoading ? null : _handleForgotPassword,
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: const Color(0xFF00C9FF)
                                          .withOpacity(0.9),
                                      fontSize: 13,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // LOGIN Button
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
                                  onPressed: _isLoading ? null : _handleLogin,
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
                                          'LOGIN',
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
                              const SizedBox(height: 12), // Added spacing

                              // *** NEW: Guest Sign In Button ***
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _handleGuestSignIn,
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
                                  icon: Icon(
                                    Icons.person_outline,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  label: Text(
                                    'Continue as Guest',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  height: 24), // Original spacing

                              // Sign Up Text
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14),
                                  children: [
                                    const TextSpan(
                                        text: "Don't have an account? "),
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: const TextStyle(
                                        color: Color(0xFF00C9FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          if (!_isLoading) {
                                            Navigator.pushNamed(
                                                context, '/signup');
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
                  ],
                ),
              ),
            ),
          ),
          // *** MODIFIED LAYOUT END ***

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