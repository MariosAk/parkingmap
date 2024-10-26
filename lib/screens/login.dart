import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:parkingmap/main.dart';
import 'package:parkingmap/screens/forgotPassword.dart';
import 'package:parkingmap/screens/introductionScreen.dart';
import 'package:parkingmap/screens/register.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as cnv;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkingmap/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController textControllerEmail = TextEditingController();
  TextEditingController textControllerPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String loginResponseMessage = "";
  bool isObscuredPassword = true;

  Future<String> loginUser(email, password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var response = await http.get(Uri.parse(
          '${AppConfig.instance.apiUrl}/login-user?email=$email&password=$password'));
      var datajson = cnv.jsonDecode(response.body)["results"];
      await prefs.setString('userid',
          datajson[0]["user_id"]); //datajson["rows"][0]["user_id"] postgresql
      return response.body;
    } catch (e) {
      print(e);
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top welcome text
              Container(
                margin: const EdgeInsets.only(top: 60.0),
                child: Center(
                  child: Text(
                    "Welcome Back!",
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Log in to your account",
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email input field
                      TextFormField(
                        controller: textControllerEmail,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.lato(
                            textStyle: const TextStyle(color: Colors.black),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.blueAccent,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password input field
                      TextFormField(
                        controller: textControllerPassword,
                        decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.lato(
                              textStyle: const TextStyle(color: Colors.black),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.blueAccent,
                            ),
                            suffixIcon: IconButton(
                              icon: isObscuredPassword
                                  ? const Icon(Icons.visibility)
                                  : const Icon(
                                      Icons.visibility_off,
                                    ),
                              onPressed: () {
                                setState(() {
                                  isObscuredPassword = !isObscuredPassword;
                                });
                              },
                            )),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loginResponseMessage,
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Login button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    try {
                                      AuthService()
                                          .loginUserWithEmailAndPassword(
                                              textControllerEmail.text,
                                              textControllerPassword.text)
                                          .then((UserCredential?
                                              userCredential) async {
                                        if (userCredential!.user != null &&
                                            !userCredential
                                                .user!.emailVerified) {
                                          loginResponseMessage =
                                              "Please verify your email first.";
                                          setState(() {
                                            _isLoading = false;
                                          });
                                          return;
                                        }
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        var firstTime =
                                            prefs.getBool("firstLogIn");
                                        if (firstTime == null || firstTime) {
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const IntroScreen()),
                                                  (Route route) => false);
                                          prefs.setBool("firstLogin", false);
                                          return;
                                        }
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        await prefs.setBool("isLoggedIn", true);
                                        await prefs.setString(
                                            "email", textControllerEmail.text);
                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const MyHomePage()),
                                                (Route route) => false);
                                      }).catchError((error) {
                                        loginResponseMessage = error.toString();
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        return;
                                      });
                                    } catch (error) {
                                      loginResponseMessage =
                                          'An unexpected error occured.';
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.lato(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const RegisterPage()));
                          },
                          child: Text(
                            'Register',
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Forgot password button
                      TextButton(
                        onPressed: () {
                          // Add navigation to forgot password screen
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()));
                        },
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
