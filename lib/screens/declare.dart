import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkingmap/services/parking_service.dart';
import 'package:parkingmap/services/points_service.dart';
import 'package:provider/provider.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';
import '../dependency_injection.dart';
import '../enums/cooldown_type_enum.dart';
import '../model/location.dart';
import '../services/auth_service.dart';
import '../tools/cooldown_widget.dart';

class DeclareSpotScreen extends StatefulWidget  {
  const DeclareSpotScreen({super.key});

  @override
  State<DeclareSpotScreen> createState() => _DeclareSpotScreenState();
}

class _DeclareSpotScreenState extends State<DeclareSpotScreen> {
  final ParkingService _parkingService = getIt<ParkingService>();
  final PointsService _pointsService = getIt<PointsService>();
  final AuthService _authService = getIt<AuthService>();

  final cooldownLimit = const Duration(minutes: 2);
  Duration? _cooldownRemaining;
  bool _loadingCooldown = true;

  @override
  void initState() {
    super.initState();
    _loadCooldown();
  }

  Future<void> _loadCooldown() async {
    final remaining = await globals.getRemainingCooldown(
      cooldownLimit,
      CooldownType.declare,
    );

    if (!mounted) return;

    setState(() {
      _cooldownRemaining = remaining;
      _loadingCooldown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCooldown) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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

            Center(
              child: CooldownButton(
                title: "I have vacated a parking spot",
                icon: Icons.local_parking_rounded,
                cooldownDuration: cooldownLimit,
                initialRemaining: _cooldownRemaining ?? Duration.zero,
                //cooldownDuration: const Duration(minutes: 5), // Set your desired cooldown
                //cooldownKey: 'lastDeclareTime', // A unique key for this action
                onPressed: () async {
                  // This code only runs when the button is NOT on cooldown.
                  final location = Provider.of<LocationProvider>(context, listen: false).currentLocation;
                  final uid = await _authService.getCurrentUserUID();

                  if (location == null || uid == null) {
                    globals.showToast(context, "Could not get user or location data.", ToastificationType.error);
                    return false;
                  }

                  final result = await _parkingService.addLeaving(location, uid);

                  if (!context.mounted) return false;

                  if (result.success) {
                    //startCooldown();
                    //_loadCooldown();

                    toastification.show(
                        context: context,
                        type: ToastificationType.success,
                        style: ToastificationStyle.flat,
                        title: Text(result.reason),
                        alignment: Alignment.bottomCenter,
                        autoCloseDuration: const Duration(seconds: 4),
                        borderRadius: BorderRadius.circular(100.0),
                        boxShadow: lowModeShadow,
                        showProgressBar: false);

                    _pointsService.updatePoints();
                    return true;
                  } else {
                    globals.showToast(context, result.reason, ToastificationType.error);
                    return false;
                  }
                },
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
