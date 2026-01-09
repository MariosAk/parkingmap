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

// Refined Color Palette
const kPrimaryColor = Color(0xFF2D7FF9); // Slightly deeper, more professional blue
const kAccentColor = Color(0xFF00D2FF);
const kBgGradient = [Color(0xFFE0EAFC), Color(0xFFCFDEF3)]; // Silky smooth gradient

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
    if (widget.accountDeleted == true) {
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

  Future<void> _performLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginResponseMessage = "";
    });

    try {
      UserCredential? userCredential = await _authService.loginUserWithEmailAndPassword(
        textControllerEmail.text.trim(),
        textControllerPassword.text.trim(),
      );

      if (userCredential?.user == null) throw 'Login failed.';
      if (!userCredential!.user!.emailVerified) throw 'Please verify your email.';

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
      setState(() => _loginResponseMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kBgGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),

                  // Logo Section with a subtle shadow
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Subtle background glow
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryColor.withOpacity(0.1),
                            ),
                          ),
                          // 2. Outlined Circle
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kPrimaryColor.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          // 3. The Main Icon
                          const Icon(
                            Icons.local_parking_rounded,
                            size: 50,
                            color: kPrimaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Text(
                    "ParkingMap",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "Find your spot, effortlessly.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.blueGrey[400],
                    ),
                  ),

                  SizedBox(height: size.height * 0.06),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: textControllerEmail,
                            hint: "Email Address",
                            icon: Icons.alternate_email_rounded,
                            type: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: textControllerPassword,
                            hint: "Password",
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),

                          if (_loginResponseMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(
                                _loginResponseMessage,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.poppins(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shadowColor: kPrimaryColor.withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _performLogin,
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("New here? ", style: GoogleFonts.poppins(color: Colors.blueGrey)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RegisterPage())),
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _isObscuredPassword : false,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: kPrimaryColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscuredPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey[400],
            size: 20,
          ),
          onPressed: () => setState(() => _isObscuredPassword = !_isObscuredPassword),
        )
            : null,
        filled: true,
        fillColor: Colors.blueGrey[50]!.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Field required' : null,
    );
  }
}
