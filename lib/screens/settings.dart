import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/services/globals.dart' as globals;

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        _showAccountInfo(context);
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
                          globals.signOutAndNavigate(context);
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

  // Change Password Dialog
  void _changePassword(BuildContext context) {
    final TextEditingController _passwordController = TextEditingController();
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
                controller: _passwordController,
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
                _updatePassword(_passwordController.text);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password updated successfully!")),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password update failed: $error")),
        );
      }
    }
  }
}
