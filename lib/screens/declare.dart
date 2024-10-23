import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/globals.dart' as globals;

class DeclareSpotScreen extends StatelessWidget {
  double latitude, longitude;
  String token;

  DeclareSpotScreen(
      {required this.latitude, required this.longitude, required this.token});

  addLeaving() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('userid');
      userId = await AuthService().getCurrentUserUID();
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/add-leaving'),
          body: cnv.jsonEncode({
            "user_id": userId.toString(),
            "lat": latitude.toString(),
            "long": longitude.toString(),
            "uid": token,
            "newParking": "false",
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      return response.body;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Parking Spot',
          style:
              GoogleFonts.robotoSlab(textStyle: TextStyle(color: Colors.black)),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white, // You can change the color here
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vacate Spot",
              style: GoogleFonts.robotoSlab(
                textStyle: const TextStyle(
                  fontSize: 22, // Section title font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30), // Add space between title and button

            // Button: "I have vacated a parking spot"
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Add your logic to declare the parking spot here
                  addLeaving();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Spot has been vacated!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.zero, // Rectangle shape (no rounding)
                    ),
                    backgroundColor: Colors.blue, // Button color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    foregroundColor: Colors.white),
                label: Text("I have vacated a parking spot",
                    style: GoogleFonts.robotoSlab()),
                icon: const Icon(Icons.local_parking_rounded),
                iconAlignment: IconAlignment.start,
              ),
            ),
            const SizedBox(
                height: 10), // Space between button and the next section

            // Description text below the button
            Text(
              "Tap the button to notify others that the spot is now available.",
              style: GoogleFonts.robotoSlab(
                textStyle: TextStyle(
                  fontSize: 16, // Description font size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
