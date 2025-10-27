import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool loading = false;
  bool isPhoneLogin = false;
  String verificationId = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // 🔹 Email Login
  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      await _authService.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showSnack("Login failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // 🔹 Forgot Password
  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnack("Enter your email to reset password");
      return;
    }
    try {
      await _authService.sendPasswordReset(email);
      _showSnack("Password reset email sent");
    } catch (e) {
      _showSnack("Error: $e");
    }
  }

  // 🔹 Google Sign-In
  Future<void> signInWithGoogle() async {
    setState(() => loading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showSnack("Google Sign-In failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // 🔹 Guest Login
  Future<void> guestLogin() async {
    setState(() => loading = true);
    try {
      await _authService.guestLogin();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showSnack("Guest login failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // 🔹 Send OTP
  Future<void> sendOtp() async {
    final phoneNumber = phoneController.text.trim();
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      _showSnack("Enter valid 10-digit phone number");
      return;
    }

    setState(() => loading = true);
    await _authService.sendOtp(
      phoneNumber: '+91$phoneNumber',
      verified: (cred) async {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
      failed: (e) {
        _showSnack(e.message ?? "OTP verification failed");
        setState(() => loading = false);
      },
      codeSent: (verId) {
        setState(() {
          verificationId = verId;
          loading = false;
        });
        _showSnack("OTP sent successfully");
      },
    );
  }

  // 🔹 Verify OTP
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      _showSnack("Enter valid 6-digit OTP");
      return;
    }

    try {
      await _authService.verifyOtp(verificationId, otp);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showSnack("Invalid OTP: $e");
    }
  }

  // 🔹 Snackbar Helper
  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // 🔹 Primary Button Widget
  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String text,
    bool showLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: showLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: showLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  // 🔹 Google Button with Local Image
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          elevation: 1,
        ),
        onPressed: loading ? null : signInWithGoogle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assests/images/google_logo.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign in with Google',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isPhoneLogin ? "Phone Login" : "Email Login"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isPhoneLogin = !isPhoneLogin;
                emailController.clear();
                passwordController.clear();
                phoneController.clear();
                otpController.clear();
                verificationId = '';
                loading = false;
              });
            },
            child: Text(
              isPhoneLogin ? "Use Email" : "Use Phone",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Welcome Back! 👋",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                if (!isPhoneLogin) ...[
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Please enter email";
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) return "Enter valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter password";
                      if (value.length < 6)
                        return "Password must be at least 6 characters";
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: forgotPassword,
                      child: const Text("Forgot Password?"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPrimaryButton(
                    onPressed: loginUser,
                    text: "Login",
                    showLoading: loading,
                  ),
                ] else ...[
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixText: "+91 ",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPrimaryButton(
                    onPressed: sendOtp,
                    text: "Send OTP",
                    showLoading: loading,
                  ),
                  if (verificationId.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: "Enter 6-digit OTP",
                        border: OutlineInputBorder(),
                        counterText: "",
                        prefixIcon: Icon(Icons.sms),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPrimaryButton(
                      onPressed: verifyOtp,
                      text: "Verify OTP & Login",
                    ),
                  ],
                ],

                const SizedBox(height: 30),
                const Text("OR", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                _buildGoogleButton(),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  onPressed: guestLogin,
                  text: "Continue as Guest",
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    "Create new account",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
