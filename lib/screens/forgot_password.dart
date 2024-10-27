import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  // Placeholder function for sending reset email
  Future<void> _sendResetPasswordEmail(String email) async {
    setState(() {
      _isLoading = true;
    });

    await AuthService().sendResetPasswordEmail(email);

    setState(() {
      _isLoading = false;
      _isEmailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Forgot Password",
          style: GoogleFonts.openSans(
              textStyle: const TextStyle(color: Colors.black)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and Instruction Text
              Text(
                "Reset your password",
                style: GoogleFonts.openSans(
                    textStyle: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter the email address associated with your account, and we'll send you an email to reset your password.",
                style: GoogleFonts.openSans(
                    textStyle:
                        const TextStyle(fontSize: 14, color: Colors.black54)),
              ),
              const SizedBox(height: 40),

              // Email Input Field
              TextFormField(
                controller: _emailController,
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
              const SizedBox(height: 30),

              // Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_emailController.text.isNotEmpty) {
                          _sendResetPasswordEmail(_emailController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text("Send Reset Link",
                          style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ))),
                    ),

              const SizedBox(height: 20),

              // Message if email was sent
              if (_isEmailSent)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "A password reset link has been sent to ${_emailController.text}",
                          style: GoogleFonts.openSans(
                              textStyle: const TextStyle(color: Colors.green)),
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
}
