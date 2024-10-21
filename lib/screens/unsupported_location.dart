// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class UnsupportedLocation extends StatelessWidget {
//   const UnsupportedLocation({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: Center(
//             child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//           Container(
//               color: const Color.fromRGBO(246, 255, 255, 1.0),
//               child: SafeArea(
//                   child: CircleAvatar(
//                 backgroundColor: const Color.fromRGBO(246, 255, 255, 1.0),
//                 radius: 100,
//                 child: Image.asset('Images/location.gif'),
//               ))),
//           Text(
//             "Your current location is not supported yet.",
//             style: GoogleFonts.openSans(
//                 textStyle: const TextStyle(color: Colors.black),
//                 fontWeight: FontWeight.w600,
//                 fontSize: 20),
//             textAlign: TextAlign.center,
//           ),
//         ])));
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/services/globals.dart' as global;

class UnsupportedLocation extends StatelessWidget {
  const UnsupportedLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFFF), // Light background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location GIF
              CircleAvatar(
                backgroundColor: const Color(0xFFF6FFFF),
                radius: 100,
                child: Image.asset('Assets/Images/location.gif'),
              ),
              const SizedBox(height: 30),

              // Main Message Text
              Text(
                "Oops! Unsupported Location",
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              // Subtext to inform the user
              Text(
                "Your current location is not supported yet.",
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    color: Colors.black54,
                    fontSize: 18,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Add an action button or exit button for better UX
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shadowColor: Colors.grey,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  await global.signOutAndNavigate(context);
                },
                child: Text(
                  'Go Back',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Optional exit or more info button
              TextButton(
                onPressed: () {
                  // Option for the user to try again or go somewhere else
                },
                child: Text(
                  'Learn More',
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
    );
  }
}
