import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/main.dart';
import 'package:parkingmap/screens/forgot_password.dart';
import 'package:parkingmap/screens/introduction_screen.dart';
import 'package:parkingmap/screens/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:toastification/toastification.dart';

import '../dependency_injection.dart';
import '../services/globals.dart' as globals;

// Define a constant for the blue color for consistency
const kPrimaryColor = Color(0xFF3A82F8);
const kPrimaryLightColor = Color(0xFFD3E5FF);

class LoginPage extends StatefulWidget {
  final bool? accountDeleted;
  const LoginPage({this.accountDeleted = false, super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController textControllerEmail = TextEditingController();
  final TextEditingController textControllerPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _loginResponseMessage = "";
  bool _isObscuredPassword = true;
  final AuthService _authService = getIt<AuthService>();

  @override
  void initState() {
    super.initState();
    // This logic for showing a toast on widget build is good.
    if (widget.accountDeleted == true) {
      // Use addPostFrameCallback to ensure context is available.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: const Text("Account deleted successfully"),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 4),
            borderRadius: BorderRadius.circular(100.0),
            showProgressBar: false);
      });
    }
  }

  /// --- NEW LOGIN LOGIC ---
  /// Encapsulates the login process for better readability and error handling.
  Future<void> _performLogin() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if form is invalid
    }

    setState(() {
      _isLoading = true;
      _loginResponseMessage = ""; // Clear previous error messages
    });

    try {
      UserCredential? userCredential = await _authService.loginUserWithEmailAndPassword(
        textControllerEmail.text.trim(),
        textControllerPassword.text.trim(),
      );

      if (userCredential?.user == null) {
        throw 'Login failed. Please try again.';
      }

      if (!userCredential!.user!.emailVerified) {
        throw 'Please verify your email before logging in.';
      }

      final prefs = await SharedPreferences.getInstance();
      bool isFirstLogin = prefs.getBool("firstLogIn") ?? true;

      await globals.initializeUid();

      if (!mounted) return;

      if (isFirstLogin) {
        await prefs.setBool("firstLogIn", false);
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const IntroScreen()),
                (Route route) => false);
      } else {
        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("email", textControllerEmail.text.trim());
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyHomePage()),
                (Route route) => false);
      }
    } catch (error) {
      setState(() {
        _loginResponseMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      // --- NEW: Use a gradient background for visual appeal ---
      body: Container(
        width: double.infinity,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryLightColor,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),

                // --- NEW: Illustrative Asset ---
                Image.asset(
                  'Assets/Images/parking-location.png', // Make sure you have an image here
                  height: screenHeight * 0.15,
                  color: kPrimaryColor.withOpacity(0.8),
                ),
                const SizedBox(height: 20),

                // --- NEW: App Name Title ---
                Text(
                  "ParkingMap",
                  style: GoogleFonts.lato(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                Text(
                  "Welcome Back!",
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),

                // --- NEW: Form wrapped in a styled container ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- NEW: Refactored TextFormField Style ---
                        TextFormField(
                          controller: textControllerEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration('Email', Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            // Optional: Add more robust email validation
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: textControllerPassword,
                          obscureText: _isObscuredPassword,
                          decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscuredPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: kPrimaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscuredPassword = !_isObscuredPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Error Message Display
                        if (_loginResponseMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Text(
                              _loginResponseMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                          ),

                        // Forgot Password link (moved up)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                            child: const Text('Forgot Password?'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- NEW: Refactored Login Button ---
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _performLogin,
                          child: Text(
                            'Login',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),

                // --- NEW: "Don't have an account?" section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const RegisterPage()));
                      },
                      child: const Text(
                        'Register Now',
                        style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --- NEW: Helper method to avoid repeating decoration code ---
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: kPrimaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
    );
  }
}
