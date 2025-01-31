import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:parkingmap/services/points_service.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';
import '../model/location.dart';

class DeclareSpotScreen extends StatelessWidget {
  final String token;

  const DeclareSpotScreen({super.key, required this.token});

  Future<Response?> addLeaving(LocationData? location) async {
    try {
      var userId = await AuthService().getCurrentUserUID();
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/add-leaving'),
          body: cnv.jsonEncode({
            "user_id": userId.toString(),
            "lat": location!.latitude!.toString(),
            "long": location.longitude!.toString(),
            "uid": token,
            "newParking": "false",
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      return response;
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Parking Spot',
          style: GoogleFonts.robotoSlab(
              textStyle: const TextStyle(color: Colors.black)),
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
                  final location =
                      Provider.of<LocationProvider>(context, listen: false)
                          .currentLocation;
                  addLeaving(location).then(
                    (value) {
                      if (value != null && value.statusCode == 200) {
                        toastification.show(
                            context: context,
                            type: ToastificationType.success,
                            style: ToastificationStyle.flat,
                            title: const Text("Spot has been vacated!"),
                            alignment: Alignment.bottomCenter,
                            autoCloseDuration: const Duration(seconds: 4),
                            borderRadius: BorderRadius.circular(100.0),
                            boxShadow: lowModeShadow,
                            showProgressBar: false);

                        PointsService().updatePoints();
                      } else {
                        globals.showServerErrorToast(context);
                      }
                    },
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
            Center(
              child: Text(
                "Tap the button to notify others that the spot is now available.",
                style: GoogleFonts.robotoSlab(
                  textStyle: const TextStyle(
                    fontSize: 16, // Description font size
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
