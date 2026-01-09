import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parkingmap/screens/login.dart';
import 'package:parkingmap/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkingmap/services/auth_service.dart';

import '../dependency_injection.dart';

// Brand Colors (Consistent with Login)
const kPrimaryColor = Color(0xFF3A82F8);
const kBackgroundColor = Colors.white;
const kInputFillColor = Color(0xFFF5F6FA);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController textControllerEmail = TextEditingController();
  final TextEditingController textControllerPassword = TextEditingController();
  final TextEditingController textControllerRepeatPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _registrationMessage = "";
  bool _registrationSuccess = false;

  bool _isObscuredPassword = true;
  bool _isObscuredRepeatPassword = true;

  String? token;

  final UserService _userService = getIt<UserService>();
  final AuthService _authService = getIt<AuthService>();

  @override
  void initState() {
    super.initState();
    _getDevToken();
  }

  Future<void> _getDevToken() async {
    token = await FirebaseMessaging.instance.getToken();
  }

  @override
  void dispose() {
    textControllerEmail.dispose();
    textControllerPassword.dispose();
    textControllerRepeatPassword.dispose();
    super.dispose();
  }

  Future<void> _performRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _registrationMessage = "";
    });

    try {
      User? user = await _authService.createUserWithEmailAndPassword(
        textControllerEmail.text.trim(),
        textControllerPassword.text.trim(),
      );

      if (user != null) {
        bool success = await _userService.registerUser(
          user.uid,
          textControllerEmail.text.trim(),
          token,
        );

        if (success) {
          setState(() {
            _registrationSuccess = true;
            _registrationMessage = 'Registration successful! Please check your email to verify your account.';
          });
        } else {
          throw 'Failed to create user profile in database.';
        }
      }
    } catch (error) {
      setState(() {
        _registrationSuccess = false;
        _registrationMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 1. Header Section ---
                Text(
                  "Create Account",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Join us to find parking easier & faster",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),

                // --- 2. Registration Form ---
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email
                      _buildTextField(
                        controller: textControllerEmail,
                        label: 'Email Address',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          // Simple regex for email validation
                          if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password
                      _buildTextField(
                        controller: textControllerPassword,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isObscured: _isObscuredPassword,
                        onVisibilityToggle: () {
                          setState(() {
                            _isObscuredPassword = !_isObscuredPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your password';
                          if (value.length < 6) return 'Min 6 characters required';
                          if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) return 'Needs a lowercase letter';
                          if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) return 'Needs an uppercase letter';
                          if (!RegExp(r'^(?=.*?[!@#\$&*~])').hasMatch(value)) return 'Needs a special character';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Repeat Password
                      _buildTextField(
                        controller: textControllerRepeatPassword,
                        label: 'Repeat Password',
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                        isObscured: _isObscuredRepeatPassword,
                        onVisibilityToggle: () {
                          setState(() {
                            _isObscuredRepeatPassword = !_isObscuredRepeatPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please repeat your password';
                          if (value != textControllerPassword.text) return 'Passwords do not match';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Status Message Area
                      if (_registrationMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: _registrationSuccess
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _registrationSuccess ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _registrationSuccess ? Icons.check_circle : Icons.error_outline,
                                color: _registrationSuccess ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _registrationMessage,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Sign Up Button
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _performRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Text(
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- 3. Footer ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                              (Route<dynamic> route) => false,
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // Extra spacing for bottom
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Text Fields ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isObscured : false,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 15),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey[400],
            size: 22,
          ),
          onPressed: onVisibilityToggle,
        )
            : null,
        filled: true,
        fillColor: kInputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
