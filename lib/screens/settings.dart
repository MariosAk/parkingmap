import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'package:parkingmap/services/globals.dart' as global;

import '../tools/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  Future<Response?> deleteUser(String? userID) async {
    try {
      if (userID != null) {
        var response = await http.delete(
            Uri.parse("${AppConfig.instance.apiUrl}/delete-user"),
            body: cnv.jsonEncode({"userID": userID}),
            headers: {
              "Content-Type": "application/json",
              "Authorization": globals.securityToken!
            });
        return response;
      } else {
        return null;
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top title
              Container(
                margin: const EdgeInsets.only(top: 60.0),
                child: Center(
                  child: Text(
                    "Settings",
                    style: GoogleFonts.robotoSlab(
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
              // Account Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.account_circle,
                          color: Colors.blueAccent),
                      title: Text(
                        "Account Information",
                        style: GoogleFonts.robotoSlab(
                          textStyle: const TextStyle(color: Colors.black),
                        ),
                      ),
                      subtitle: Text(
                        FirebaseAuth.instance.currentUser?.email ??
                            "Email not available",
                        style: GoogleFonts.robotoSlab(
                          textStyle: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      onTap: () {
                        //_showAccountInfo(context);
                      },
                    ),
                    const Divider(color: Colors.black),

                    // Notification Toggle
                    SwitchListTile(
                      title: Text(
                        "Enable Notifications",
                        style: GoogleFonts.robotoSlab(
                          textStyle: const TextStyle(color: Colors.black),
                        ),
                      ),
                      value: false,
                      onChanged: null,
                      secondary: const Icon(Icons.notifications,
                          color: Colors.blueAccent),
                    ),
                    const Divider(color: Colors.black),

                    // Change Password
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.blueAccent),
                      title: Text(
                        "Change Password",
                        style: GoogleFonts.robotoSlab(
                          textStyle: const TextStyle(color: Colors.black),
                        ),
                      ),
                      onTap: () {
                        globals.showSoonToComeToast(context);
                      },
                    ),
                    const Divider(color: Colors.black),

                    ListTile(
                      leading: const Icon(Icons.no_accounts, color: Colors.red),
                      title: Text(
                        "Delete Account",
                        style: GoogleFonts.robotoSlab(
                          textStyle: const TextStyle(color: Colors.black),
                        ),
                      ),
                      onTap: () {
                        _deleteAccountPrompt(context);
                      },
                    ),
                    const Divider(color: Colors.black),

                    // Sign Out Button
                    const SizedBox(height: 40),
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
                        onPressed: () async {
                          _confirmSignOut(context);
                        },
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.robotoSlab(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows for the content to be scrollable
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.5, // Set height to half the screen
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(16.0)), // Rounded top corners
          ),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.yellow[700],
                  size: 50,
                ),
              ]),
              const SizedBox(height: 16), // Add spacing
              const Text(
                "Are you sure you want to sign out?",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text(
                "If you sign out you will have to fill your email and password again. Do you want to continue?",
                style: TextStyle(fontSize: 16, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

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
                  onPressed: () async {
                    globals.signOutAndNavigate(context);
                  },
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.robotoSlab(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                },
                child: Text(
                  "Cancel",
                  style: GoogleFonts.robotoSlab(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Account Information Dialog
  void _showAccountInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Account Information",
            style: GoogleFonts.robotoSlab(
              textStyle: const TextStyle(color: Colors.black),
            ),
          ),
          content: Text(
            "Email: ${FirebaseAuth.instance.currentUser?.email ?? 'N/A'}",
            style: GoogleFonts.robotoSlab(
              textStyle: const TextStyle(color: Colors.black54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Close",
                style: GoogleFonts.robotoSlab(
                  textStyle: const TextStyle(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccountPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows for the content to be scrollable
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.5, // Set height to half the screen
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(16.0)), // Rounded top corners
          ),
          child: Column(
            children: [
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 50,
                ),
              ]),
              const SizedBox(height: 16), // Add spacing
              const Text(
                "Are you sure?",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text(
                "If you delete your account you won't be able to log in with it anymore. This action is irreversible. Do you want to continue?",
                style: TextStyle(fontSize: 16, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _doDelete();
                  },
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.robotoSlab(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                },
                child: Text(
                  "Cancel",
                  style: GoogleFonts.robotoSlab(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align label to start
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.robotoSlab(
            textStyle: const TextStyle(color: Colors.black), // Text color
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.robotoSlab(
              textStyle: const TextStyle(color: Colors.black54),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black), // Underline color
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                  color: Colors.red), // Change underline color when focused
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide:
                  BorderSide(color: Colors.red), // Underline color for errors
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0), // Padding inside the TextField
          ),
        ),
      ],
    );
  }

  void _doDelete() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows for the content to be scrollable
      builder: (BuildContext context) {
        return SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height *
                  0.5, // Set height to half the screen
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.0)), // Rounded top corners
              ),
              child: Column(
                children: [
                  const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red,
                          size: 50,
                        ),
                      ]),
                  const Text(
                    "Use your credentials to verify as a last step for authentication.",
                    style: TextStyle(fontSize: 16, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16), // Add spacing
                  _buildTextField("Email", emailController, false),
                  const SizedBox(height: 10),
                  _buildTextField("Password", passwordController, true),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        var userID = await AuthService().getCurrentUserUID();
                        AuthService()
                            .deleteCurrentUser(
                                emailController.text, passwordController.text)
                            .then(
                          (value) async {
                            if (value) {
                              deleteUser(userID).then(
                                (value) {
                                  if (value != null &&
                                      value.statusCode == 200) {
                                    global.signOutAndNavigate(context,
                                        accountDeleted: true);
                                  } else {
                                    globals.showServerErrorToast(context);
                                  }
                                },
                              );
                            } else {
                              toastification.show(
                                  context: context,
                                  type: ToastificationType.error,
                                  style: ToastificationStyle.flat,
                                  title: const Text("Something went wrong"),
                                  description: const Text(
                                      "Your account was not deleted."),
                                  alignment: Alignment.bottomCenter,
                                  autoCloseDuration: const Duration(seconds: 4),
                                  borderRadius: BorderRadius.circular(100.0),
                                  boxShadow: lowModeShadow,
                                  showProgressBar: false);
                            }
                          },
                        );
                      } catch (error) {
                        if (context.mounted) {
                          toastification.show(
                              context: context,
                              type: ToastificationType.error,
                              style: ToastificationStyle.flat,
                              title: const Text("Something went wrong"),
                              description:
                                  const Text("Your account was not deleted."),
                              alignment: Alignment.bottomCenter,
                              autoCloseDuration: const Duration(seconds: 4),
                              borderRadius: BorderRadius.circular(100.0),
                              boxShadow: lowModeShadow,
                              showProgressBar: false);
                        }
                      }
                    },
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.robotoSlab(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Dismiss dialog
                    },
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }

  // Change Password Dialog
  void _changePassword(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Change Password",
            style: GoogleFonts.robotoSlab(
              textStyle: const TextStyle(color: Colors.black),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your new password below.",
                style: GoogleFonts.robotoSlab(
                  textStyle: const TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  labelStyle: GoogleFonts.robotoSlab(
                    textStyle: const TextStyle(color: Colors.black),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updatePassword(passwordController.text);
                Navigator.of(context).pop();
              },
              child: Text(
                "Update",
                style: GoogleFonts.robotoSlab(
                  textStyle: const TextStyle(color: Colors.blueAccent),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.robotoSlab(
                  textStyle: const TextStyle(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update Password
  void _updatePassword(String newPassword) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && newPassword.isNotEmpty) {
      try {
        await user.updatePassword(newPassword);
        if (!mounted) return;
        toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: const Text("Password updated successfully!"),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 4),
            borderRadius: BorderRadius.circular(100.0),
            boxShadow: lowModeShadow,
            showProgressBar: false);
      } catch (error) {
        toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            title: const Text("Password update failed"),
            description: Text("$error"),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 4),
            borderRadius: BorderRadius.circular(100.0),
            boxShadow: lowModeShadow,
            showProgressBar: false);
      }
    }
  }
}
