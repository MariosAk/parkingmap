import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parkingmap/screens/login.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert' as cnv;
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/globals.dart' as globals;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  TextEditingController textControllerEmail = TextEditingController();
  TextEditingController textControllerPassword = TextEditingController();
  TextEditingController textControllerRepeatPassword = TextEditingController();
  bool isEmailValid = false;
  bool registrationSuccess = false;
  late String registrationStatus;
  String? token;
  String registrationMessage = "";
  final _formKey = GlobalKey<FormState>();
  bool isObscuredPassword = true;
  bool isObscuredRepeatPassword = true;
  bool errorMessageVisible = false;

  Future registerUser(uid, email, password, fcmToken) async {
    try {
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/register-user"),
          body: cnv.jsonEncode({
            "uid": uid,
            "email": email,
            "password": password,
            "fcm_token": fcmToken
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      registrationStatus = response.body;
      if (registrationStatus.contains("successful")) {
        registrationSuccess = true;
      } else if (registrationStatus.contains("exists")) {
        registrationSuccess = false;
      } else {
        registrationSuccess = false;
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future _getDevToken() async {
    token = await FirebaseMessaging.instance.getToken();
  }

  @override
  void dispose() {
    textControllerEmail.dispose();
    textControllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([_getDevToken()]),
        builder: (context, snapshot) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 70),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          Text(
                            "Register",
                            style: GoogleFonts.lato(
                              color: Colors.black,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          "Start your parking assisted journey with us!",
                          style: GoogleFonts.lato(
                            color: Colors.black54,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "The password must be at least 6 characters long and include a combination of lowercase letters, uppercase letters, and special characters.",
                          style: GoogleFonts.lato(
                            color: Colors.black54,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Visibility(
                          visible: errorMessageVisible,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: registrationSuccess
                                  ? Colors.greenAccent.withOpacity(0.3)
                                  : Colors.redAccent.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: registrationSuccess
                                        ? Colors.green
                                        : Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    registrationMessage,
                                    style: GoogleFonts.openSans(
                                        textStyle: TextStyle(
                                            color: registrationSuccess
                                                ? Colors.green
                                                : Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                                const SizedBox(height: 40),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      _buildTextField(
                                        controller: textControllerEmail,
                                        hintText: "Email",
                                        icon: Icons.email_outlined,
                                        obscureText: false,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildTextField(
                                        controller: textControllerPassword,
                                        hintText: "Password",
                                        icon: Icons.lock_outline,
                                        obscureText: isObscuredPassword,
                                        iconButton: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                isObscuredPassword =
                                                    !isObscuredPassword;
                                              });
                                            },
                                            icon: isObscuredPassword
                                                ? const Icon(Icons.visibility)
                                                : const Icon(
                                                    Icons.visibility_off)),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters long';
                                          }
                                          if (!RegExp(r'^(?=.*[a-z])')
                                              .hasMatch(value)) {
                                            return 'Password must contain at least one lowercase letter';
                                          }
                                          if (!RegExp(r'^(?=.*[A-Z])')
                                              .hasMatch(value)) {
                                            return 'Password must contain at least one uppercase letter';
                                          }
                                          if (!RegExp(r'^(?=.*?[!@#\$&*~])')
                                              .hasMatch(value)) {
                                            return 'Password must contain at least one special character';
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildTextField(
                                        controller:
                                            textControllerRepeatPassword,
                                        hintText: "Repeat Password",
                                        icon: Icons.lock_outline,
                                        obscureText: isObscuredRepeatPassword,
                                        iconButton: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                isObscuredRepeatPassword =
                                                    !isObscuredRepeatPassword;
                                              });
                                            },
                                            icon: isObscuredRepeatPassword
                                                ? const Icon(Icons.visibility)
                                                : const Icon(
                                                    Icons.visibility_off)),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty ||
                                              value !=
                                                  textControllerPassword.text) {
                                            return 'Please retype your password correctly';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                    onPressed: () async {
                                      try {
                                        if (_formKey.currentState!.validate()) {
                                          // registration.then((value) =>
                                          //     registrationSuccess
                                          //         ? () {
                                          //             Navigator.of(context).push(
                                          //                 MaterialPageRoute(
                                          //                     builder: (context) =>
                                          //                         CarPick(
                                          //                             textControllerEmail
                                          //                                 .text)));
                                          //             ScaffoldMessenger.of(context)
                                          //                 .showSnackBar(SnackBar(
                                          //                     content: Text(
                                          //                         registrationStatus)));
                                          //           }()
                                          //         : ScaffoldMessenger.of(context)
                                          //             .showSnackBar(SnackBar(
                                          //                 content: Text(
                                          //                     registrationStatus))));

                                          // UserCredential userCredential =
                                          //     await FirebaseAuth.instance
                                          //         .createUserWithEmailAndPassword(
                                          //   email: textControllerEmail.text,
                                          //   password: textControllerPassword.text,
                                          // );

                                          // // Send email verification
                                          // await userCredential.user
                                          //     ?.sendEmailVerification();
                                          AuthService()
                                              .createUserWithEmailAndPassword(
                                                  textControllerEmail.text,
                                                  textControllerPassword.text)
                                              .then((User? user) {
                                            registerUser(
                                                user!.uid,
                                                textControllerEmail.text,
                                                textControllerPassword.text,
                                                token);
                                            setState(() {
                                              registrationMessage =
                                                  'Registration successful! Please check your email to verify your account.';
                                              registrationSuccess = true;
                                              errorMessageVisible = true;
                                            });
                                          }).catchError((error) {
                                            setState(() {
                                              registrationMessage =
                                                  error.toString();
                                              registrationSuccess = false;
                                              errorMessageVisible = true;
                                            });
                                          });
                                        }
                                      } catch (error) {
                                        setState(() {
                                          registrationMessage =
                                              'An unexpected error occured.';
                                          registrationSuccess = false;
                                          errorMessageVisible = true;
                                        });
                                        return;
                                      }
                                      //}
                                    },
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: () {
                                    // Add navigation to login or help page if needed
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                  child: const Text(
                                    "Already have an account? Sign in",
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    IconButton? iconButton,
    required bool obscureText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          suffixIcon: iconButton,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
