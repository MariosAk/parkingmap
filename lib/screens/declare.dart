import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkingmap/services/parking_service.dart';
import 'package:parkingmap/services/points_service.dart';
import 'package:provider/provider.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';
import '../dependency_injection.dart';
import '../model/location.dart';
import '../services/auth_service.dart';

class DeclareSpotScreen extends StatelessWidget {
  final ParkingService _parkingService = getIt<ParkingService>();
  final PointsService _pointsService = getIt<PointsService>();
  final AuthService _authService = getIt<AuthService>();

  DeclareSpotScreen({super.key});

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
                onPressed: () async {
                  // Add your logic to declare the parking spot here
                  final location =
                      Provider.of<LocationProvider>(context, listen: false)
                          .currentLocation;
                  _parkingService.addLeaving(location, await _authService.getCurrentUserUID()).then(
                    (value) {
                      if (value.success) {
                        toastification.show(
                            context: context,
                            type: ToastificationType.success,
                            style: ToastificationStyle.flat,
                            title: Text(value.reason),
                            alignment: Alignment.bottomCenter,
                            autoCloseDuration: const Duration(seconds: 4),
                            borderRadius: BorderRadius.circular(100.0),
                            boxShadow: lowModeShadow,
                            showProgressBar: false);

                        _pointsService.updatePoints();
                        //_parkingService.addMarkerFromNotification(new LatLng(location!.latitude!, location!.longitude!));
                      } else {
                        globals.showToast(context, value.reason, ToastificationType.error);
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
