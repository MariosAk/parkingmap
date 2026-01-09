import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:parkingmap/enums/cooldown_type_enum.dart';
import 'package:parkingmap/model/location.dart';
import 'package:parkingmap/model/marker_model.dart';
import 'package:parkingmap/model/pushnotification_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkingmap/screens/premium_showcase_screen.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/globals.dart';
import 'package:parkingmap/services/hive_service.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:parkingmap/services/parking_service.dart';
import 'package:parkingmap/services/user_service.dart';
import 'package:parkingmap/tools/radar_widget.dart';
import 'package:provider/provider.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';

import '../dependency_injection.dart';
import '../tools/confirm_spot_taken.dart';
import '../tools/parkingspottile_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // #region variables
  final ParkingService _parkingService = getIt<ParkingService>();
  final AuthService _authService = getIt<AuthService>();
  //final UserService _userService = getIt<UserService>();

  PushNotification? notification;
  String? address, uid;
  DateTime? notifReceiveTime;

  int index = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  bool leaving = false;

  double? containerHeight, containerWidth, x, y;

  final _controller = TextEditingController();
  String searchTxt = "";
  String lat = "";
  String lon = "";
  final MapController _mapctl = MapController();
  StreamSubscription? subscription;

  int value = 0;
  //late Timer timer;
  late int leavingsCountNew;
  int? leavingsCountOld;
  late int latestRecordID;
  String userID = "";

  Location location = Location();
  // late StreamSubscription<LocationData>? _locationSubscription;
  late AnimationController _animationController;
  late Animation<double> _pulsatingAnimation;

  // Declare a variable to hold current bounds
  // Variable to hold the pulsating marker's position
  late LatLng pulsatingMarkerPosition;

  bool isMapInitialized = false;

  final PopupController _popupController = PopupController();
  final ValueNotifier<int> _spotsNotifier = ValueNotifier<int>(0);

  late StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentLocation;
  LatLng? previousLocation;
  bool _shouldCenterOnLocation = true;

  double _zoom = 20;
  String cellTopic = "";
  //late ValueNotifier<bool> radarVisibility;

  final ValueNotifier<LatLng?> _userLocationNotifier = ValueNotifier<LatLng?>(null);

  final ValueNotifier<double> _userHeadingNotifier = ValueNotifier<double>(0.0);

  // #endregion

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    //timer.cancel();
    subscription?.cancel();
    _locationSubscription?.cancel();
    _spotsNotifier.dispose();
    _userLocationNotifier.dispose();
    //radarVisibility.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    startLocationTracking();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulsatingAnimation =
        Tween<double>(begin: 0, end: 20).animate(_animationController);

    if (Provider.of<LocationProvider>(context, listen: false).currentLocation != null) {
      pulsatingMarkerPosition = LatLng(
          Provider.of<LocationProvider>(context, listen: false).currentLocation!.latitude!,
          Provider.of<LocationProvider>(context, listen: false).currentLocation!.longitude!
      );
      // Also set the notifier immediately so the list calculates distances correctly
      _userLocationNotifier.value = pulsatingMarkerPosition;

      _authService.getCurrentUserUID().then((value) {
        // _userService.sendAlive(value!, Provider.of<LocationProvider>(context, listen: false).currentLocation!.latitude!,
        //     Provider.of<LocationProvider>(context, listen: false).currentLocation!.longitude!);
        // _parkingService.getSearchingCount(Provider.of<LocationProvider>(context, listen: false).currentLocation!.latitude!,
        //     Provider.of<LocationProvider>(context, listen: false).currentLocation!.longitude!);
      });

    }

    // Timer.periodic(const Duration(seconds: 30), (_) {
    //   if (_currentLocation != null) {
    //     // Update the global searcher count for the user's area
    //     _parkingService.getSearchingCount(
    //         _currentLocation!.latitude!,
    //         _currentLocation!.longitude!
    //     );
    //   }
    // });

    //radarVisibility = ValueNotifier<bool>(globals.premiumSearchState);
  }

  void deleteMarkerReceived(LatLng markerLatLng) async {
    bool exists = _parkingService.markersNotifier.value.any((existingSpot) =>
    existingSpot.mapMarker.point.latitude == markerLatLng.latitude &&
        existingSpot.mapMarker.point.longitude == markerLatLng.longitude);
    if (exists) {
      var spot = _parkingService.markersNotifier.value
          .where((existingSpot) =>
      existingSpot.mapMarker.point.latitude == markerLatLng.latitude &&
          existingSpot.mapMarker.point.longitude == markerLatLng.longitude)
          .first;
      _parkingService.markersNotifier.value = List.from(_parkingService.markersNotifier.value)
        ..remove(spot);
      await HiveService("markersBox").deleteCachedMarker(spot);
    }
  }

  // Method to initialize and start location tracking
  void startLocationTracking() async {
    if (!mounted) return;
    // Request permission to access location
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return; // Exit if the service is not enabled
      }
    }

    // Check if permission is granted
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // Exit if permission is not granted
      }
    }

    // Subscribe to location updates
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) async {
      var oldTopic = cellTopic;
      LatLng currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      cellTopic = calculateCellTopic(
          currentLocation.latitude!, currentLocation.longitude!);

      if (previousLocation == null) {
        await FirebaseMessaging.instance
            .subscribeToTopic(cellTopic)
            .catchError((error) {});

        // previousLocation = LatLng(
        //     Provider.of<LocationProvider>(context, listen: false)
        //         .currentLocation!
        //         .latitude!,
        //     Provider.of<LocationProvider>(context, listen: false)
        //         .currentLocation!
        //         .longitude!);
        previousLocation = currentLatLng;
      } else {
        final distance = _calculateDistance(currentLatLng);

        if (oldTopic != cellTopic || distance > 500.0) {
          if (oldTopic.isNotEmpty) {
            await FirebaseMessaging.instance.unsubscribeFromTopic(oldTopic);
          }
          await FirebaseMessaging.instance
              .subscribeToTopic(cellTopic)
              .catchError((error) {});
          // _userService.sendAlive(globals.uid!, Provider.of<LocationProvider>(context, listen: false).currentLocation!.latitude!,
          //     Provider.of<LocationProvider>(context, listen: false).currentLocation!.longitude!);
        }
      }

      _currentLocation = currentLocation;

      if (previousLocation == null || currentLatLng.latitude != previousLocation!.latitude &&
          currentLatLng.longitude != previousLocation!.longitude) {
        //pulsatingMarkerPosition = currentLatLng;
        _userLocationNotifier.value = currentLatLng;
        // Move the map to the user's current position
        if (
            (previousLocation == null || _calculateDistance(currentLatLng) > 5.0)) {
          _mapctl.move(currentLatLng, 18.0);
        }
        //updateBoundsAddMarkers();
        pulsatingMarkerPosition = currentLatLng;
        previousLocation = currentLatLng;
      }

      if (currentLocation.heading != null) {
        _userHeadingNotifier.value = currentLocation.heading!;
      }
    });

    // var uid = await _authService.getCurrentUserUID();
    // Timer.periodic(
    //   const Duration(seconds: 60),
    //       (_) => _userService.sendAlive(globals.uid!, _currentLocation!.latitude!, _currentLocation!.longitude!)
    // );

  }

  String calculateCellTopic(double latitude, double longitude) {
    const gridCellSize = 0.005;
    int latCell = ((latitude) / gridCellSize).floor();
    int lngCell = ((longitude) / gridCellSize).floor();
    cellTopic = 'thessaloniki_${latCell}_$lngCell';
    return cellTopic;
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _shouldCenterOnLocation = true;
      _mapctl.move(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          18.0); // Center map on current location
      _parkingService.updateBounds(
           _mapctl.camera.visibleBounds, _mapctl.camera.zoom);
    } else {
      // Handle the case where currentPosition is still null
      toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title:
              const Text("Unable to get current location. Please try again."),
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 4),
          borderRadius: BorderRadius.circular(100.0),
          boxShadow: lowModeShadow,
          showProgressBar: false);
    }
  }

  Future<void> markSpotAsTaken(Marker marker) async {
    if (_currentLocation == null) {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title:
              const Text("Unable to get current location. Please try again."),
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 4),
          borderRadius: BorderRadius.circular(100.0),
          boxShadow: lowModeShadow,
          showProgressBar: false);
      return;
    }

    double distance = Geolocator.distanceBetween(
        marker.point.latitude,
        marker.point.longitude,
        _currentLocation!.latitude!,
        _currentLocation!.longitude!);
    if (distance > 125) {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title: const Text("You have to be closer to this spot."),
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 4),
          borderRadius: BorderRadius.circular(100.0),
          boxShadow: lowModeShadow,
          showProgressBar: false);
      return;
    }

    _parkingService.incrementReport(marker.point.latitude, marker.point.longitude).then(
        (value) {
          if (!mounted) return;

          if (value) {
            globals.showToast(context, "Spot was reported.", ToastificationType.success);
          } else {
            globals.showToast(context, "There is a 60 minute cooldown between reports. Please try again later.", ToastificationType.error);
          }
        }
    );
  }

  // Helper method to calculate distance
  double _calculateDistance(LatLng spotPosition) {
    if (pulsatingMarkerPosition == null) {
      return 0.0; // Return 0 if we don't have the user's location yet
    }
    return Geolocator.distanceBetween(
      pulsatingMarkerPosition!.latitude,
      pulsatingMarkerPosition!.longitude,
      spotPosition.latitude,
      spotPosition.longitude,
    );
  }

  Color getAgeColor(Duration age) {
    // Define your thresholds here
    const int freshLimitMinutes = 5;   // 0-10 mins: Green
    const int mediumLimitMinutes = 10;  // 10-30 mins: Yellow
    // 30+ mins: Red

    if (age.inMinutes <= freshLimitMinutes) {
      return Colors.green;
    } else if (age.inMinutes <= mediumLimitMinutes) {
      return Colors.orangeAccent; // Orange/Yellow
    } else {
      return Colors.redAccent;
    }
  }


  void _purchasePriorityPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows for the content to be scrollable
      backgroundColor: Colors.transparent, // Makes the background transparent
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.75,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.0),
                ), // More pronounced rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar for better UX
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    // Reward Icon
                    Image.asset(
                      'Assets/Images/reward.png',
                      scale: 12,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      "Redeem Your Points!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      "Earn points every time you declare an empty parking spot. Once your points reach 100, you can redeem them to get into a priority queue for a spot.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    // Points display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$points / 100",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Redeem button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 0, 174, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          var currentPoints = int.tryParse(points);
                          if (currentPoints != null && currentPoints >= 100) {
                            _showCurrentOrCustomLocationDialog(context);
                          } else {
                            toastification.show(
                                context: context,
                                type: ToastificationType.warning,
                                style: ToastificationStyle.flat,
                                title:
                                    const Text("You dont have enough points!"),
                                alignment: Alignment.bottomCenter,
                                autoCloseDuration: const Duration(seconds: 4),
                                borderRadius: BorderRadius.circular(100.0),
                                boxShadow: lowModeShadow,
                                showProgressBar: false);
                          }
                        },
                        child: Text(
                          'Take Priority',
                          style: GoogleFonts.robotoSlab(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Dismiss dialog
                      },
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.robotoSlab(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double multiplier = shortestSide >= 600 ? 0.02 : 0.05;
    double addressTextSize = screenWidth * multiplier;
    double sizedboxSize = screenHeight * 0.015;
    double myLocationButtonSize = screenWidth * multiplier;
    return Container(
        color: Colors.white,
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left-side title
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 8.0),
                  //   child: Text(
                  //     "ParkingMap",
                  //     style: GoogleFonts.robotoSlab(
                  //       textStyle:
                  //           const TextStyle(color: Colors.black, fontSize: 18),
                  //     ),
                  //   ),
                  // ),

                  // ValueListenableBuilder<bool>(
                  //   valueListenable: radarVisibility,
                  //   builder: (context, value, child) {
                  //     return Visibility(
                  //       visible: radarVisibility.value,
                  //       replacement: const Expanded(
                  //         child: Center(
                  //           child: SizedBox(
                  //             width: 50, // Same size as the radar widget
                  //             height: 50, // Same size as the radar widget
                  //           ),
                  //         ),
                  //       ),
                  //       child:
                  //           // Spacer to push radar widget to center
                  //           const Expanded(
                  //         child: Center(
                  //           child: RotatingRadarWidget(
                  //             size: 50,
                  //             color: Colors.lightBlueAccent,
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),

                  // --- LEFT SIDE: PREMIUM ---
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const PremiumShowcaseScreen(),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          // Use a very soft amber tint instead of solid amber
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.4),
                              width: 1
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                Icons.stars_rounded, // A softer icon than 'star'
                                color: Colors.amber,
                                size: 16
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "PREMIUM",
                              style: GoogleFonts.poppins( // Match app typography
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber[800], // Darker amber for readability on light background
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- RIGHT SIDE: REWARDS ---
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _purchasePriorityPrompt(context);
                        },
                        child: Image.asset('Assets/Images/reward.png', scale: 15),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, right: 10),
                        child: Text(
                          globals.points,
                          style: GoogleFonts.robotoSlab(
                            textStyle: const TextStyle(
                              color: Colors.lightBlue,
                              fontSize: 25,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 2000), // Animation speed
                    child: SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(
                                      0, 3), // changes position of shadow
                                ),
                              ],
                            ),
                            height: screenHeight / 2.5,
                            width: screenWidth,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: FlutterMap(
                                  mapController: _mapctl,
                                  options: MapOptions(
                                      initialCenter: LatLng(
                                          Provider.of<LocationProvider>(context)
                                              .currentLocation!
                                              .latitude!,
                                          Provider.of<LocationProvider>(context)
                                              .currentLocation!
                                              .longitude!),
                                      initialZoom: 18,
                                      minZoom: 16,
                                      maxZoom: 18,
                                      onMapReady: () {
                                        _parkingService.updateBounds(
                                            _mapctl.camera.visibleBounds, _mapctl.camera.zoom);
                                        subscription = _mapctl.mapEventStream.listen((MapEvent mapEvent) {
                                          if (mapEvent is MapEventMoveEnd) {
                                            _shouldCenterOnLocation = false;
                                            // When the user stops moving the map, just tell the service to update.
                                            // That's its only job.
                                            _parkingService.updateBounds(
                                                mapEvent.camera.visibleBounds, mapEvent.camera.zoom);
                                          }
                                        });
                                        isMapInitialized = true;
                                      },
                                      onPositionChanged:
                                          (position, hasGesture) {
                                        _zoom = (8 +
                                                ((40 - 20) *
                                                    ((position.zoom - 16) /
                                                        (18 - 16))))
                                            .clamp(10, 30);
                                      },
                                      onTap: (tapPosition, point) {
                                        _popupController.hideAllPopups();
                                      }),
                                  children: [
                                    TileLayer(
                                        urlTemplate:
                                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                        userAgentPackageName:
                                            "com.maappinnovations.parkingmap"),
                                    //if (isMapInitialized)
                                      //
                                      ValueListenableBuilder<double>(
                                        valueListenable: _userHeadingNotifier,
                                        builder: (context, userHeading, _) {
                                          // Listen for location updates to position the marker
                                          return ValueListenableBuilder<LatLng?>(
                                            valueListenable: _userLocationNotifier,
                                            builder: (context, userLocation, _) {
                                              // If no location yet, don't draw anything
                                              if (userLocation == null) {
                                                return const SizedBox.shrink();
                                              }

                                              // Animate the pulsating effect
                                              return AnimatedBuilder(
                                                animation: _animationController,
                                                builder: (context, child) {
                                                  return MarkerLayer(
                                                    markers: [
                                                      // COMBINED MARKER: Glow + Arrow
                                                      Marker(
                                                        // Make the marker large enough to hold the max glow size
                                                        width: (screenWidth * 0.05 * (_zoom / 15.0)) + 20 + 50,
                                                        height: (screenWidth * 0.05 * (_zoom / 15.0)) + 20 + 50,
                                                        point: userLocation,
                                                        child: Stack(
                                                          alignment: Alignment.center,
                                                          children: [
                                                            // 1. The Pulsating Glow Layer
                                                            Container(
                                                              width: (screenWidth * 0.05 * (_zoom / 15.0)) + _pulsatingAnimation.value,
                                                              height: (screenWidth * 0.05 * (_zoom / 15.0)) + _pulsatingAnimation.value,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                color: Colors.blue.withOpacity(0.3),
                                                              ),
                                                            ),

                                                            // 2. The Directional Arrow Layer
                                                            Transform.rotate(
                                                              angle: (userHeading * (3.14159 / 180)),
                                                              child: Container(
                                                                width: (screenWidth * 0.05 * (_zoom / 15.0)),
                                                                height: (screenWidth * 0.05 * (_zoom / 15.0)),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.blue,
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(color: Colors.white, width: 2),
                                                                  boxShadow: const [
                                                                    BoxShadow(
                                                                      color: Colors.black26,
                                                                      blurRadius: 3,
                                                                    )
                                                                  ],
                                                                ),
                                                                child: Icon(
                                                                  Icons.navigation_rounded,
                                                                  color: Colors.white,
                                                                  size: (screenWidth * 0.05 * (_zoom / 15.0)) * 0.6,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    Positioned(
                                      bottom: screenHeight * 0.01,
                                      right: screenHeight * 0.01,
                                      height: screenHeight * multiplier,
                                      width: screenWidth * multiplier * 2.2,
                                      child: FloatingActionButton(
                                        onPressed: _centerOnCurrentLocation,
                                        backgroundColor: Colors.white70,
                                        child: Icon(
                                          Icons.my_location,
                                          size: myLocationButtonSize,
                                        ),
                                      ),
                                    ),
                                    ValueListenableBuilder<List<ParkingSpotData>>(
                                      valueListenable: _parkingService.markersNotifier,
                                      builder: (context, parkingSpots, child) {
                                        //final mapMarkers = parkingSpots.map((spot) => spot.mapMarker).toList();
                                        final mapMarkers = parkingSpots.map((spot) {

                                          // 1. Calculate the color dynamically
                                          final age = DateTime.now().difference(spot.timestamp ?? DateTime.now());
                                          final statusColor = globals.getProbabilityColor(null, age, 0);

                                          // 2. Return a new Marker with the composite UI (Icon + Dot)
                                          return Marker(
                                            point: spot.mapMarker.point,
                                            width: (screenWidth * 0.10 * (_zoom / 15.0)), // Slightly larger to fit the glow
                                            height: (screenWidth * 0.10 * (_zoom / 15.0)),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // 1. The Glow/Halo Layer
                                                Container(
                                                  width: (screenWidth * 0.10 * (_zoom / 15.0)) ,
                                                  height: (screenWidth * 0.10 * (_zoom / 15.0)) ,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: statusColor.withOpacity(0.2), // Transparent center
                                                    border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: statusColor.withOpacity(0.4),
                                                        blurRadius: 15,
                                                        spreadRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                              Container(
                                                  width: (screenWidth * 0.02 * (_zoom / 15.0)),
                                                  height: (screenWidth * 0.02 * (_zoom / 15.0)),
                                                  decoration: BoxDecoration(
                                                    color: statusColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        blurRadius: 2,
                                                        offset: const Offset(0, 1),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                            ]
                                            ),
                                          );
                                        }).toList();
                                        return PopupMarkerLayer(
                                          options: PopupMarkerLayerOptions(
                                            markers: mapMarkers,
                                            popupController: _popupController,
                                            onPopupEvent:
                                                (event, selectedMarkers) async{
                                              if (selectedMarkers.isNotEmpty) {
                                                // Assuming you want to show the dialog for the first selected marker
                                                Marker selectedMarker =
                                                    selectedMarkers.first;

                                                const cooldownLimit = Duration(minutes: 10);
                                                Duration remaining = await globals.getRemainingCooldown(cooldownLimit, CooldownType.report);

                                                if (!mounted) return;

                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) => MarkAsTakenCooldownDialog(
                                                    cooldownRemaining: remaining,
                                                    onConfirm: () {
                                                      markSpotAsTaken(selectedMarker);
                                                    },
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ))),
                      ],
                    )),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       // The label for the toggle
                  //       Text(
                  //         "Actively searching",
                  //         style: GoogleFonts.robotoSlab(
                  //           textStyle: TextStyle(color: Colors.blue[900]),
                  //           fontWeight: FontWeight.w600,
                  //           fontSize: 16, // Adjust font size as needed
                  //         ),
                  //       ),
                  //       // The Switch widget itself
                  //       Switch(
                  //         value: _isActivelySearching,
                  //         onChanged: (newValue) {
                  //           // This function is called when the user flips the switch.
                  //           setState(() {
                  //             _isActivelySearching = newValue;
                  //           });
                  //
                  //           // Now, you can trigger your "searching" logic.
                  //           if (_isActivelySearching) {
                  //             print("Actively searching ENABLED.");
                  //             // Call the function to start searching, for example:
                  //             // _parkingService.addSearching(pulsatingMarkerPosition, "your_token");
                  //           } else {
                  //             print("Actively searching DISABLED.");
                  //             // Call the function to stop searching, if applicable.
                  //           }
                  //         },
                  //         // Customize the switch colors to match your theme
                  //         activeColor: Colors.blue,
                  //         activeTrackColor: Colors.lightBlue.withOpacity(0.5),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: sizedboxSize),
                  ValueListenableBuilder<int>(
                    valueListenable: _spotsNotifier,
                    builder: (context, spotCount, child) {
                      return Text(
                        "Available spots: $spotCount",
                        style: GoogleFonts.robotoSlab(
                            textStyle: TextStyle(color: Colors.blue[900]),
                            fontWeight: FontWeight.w900,
                            fontSize: addressTextSize),
                        textAlign: TextAlign.left,
                      );
                    },
                  ),

            Expanded(
              child: ValueListenableBuilder<LatLng?>(
                valueListenable: _userLocationNotifier,
                builder: (context, userLocation, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: _parkingService.searchingCountNotifier,
                    builder: (context, searchingCount, _) {
                      return ValueListenableBuilder<List<ParkingSpotData>>(
                        valueListenable: _parkingService.markersNotifier,
                        builder: (context, allSpots, _) {
                          if (!isMapInitialized) {
                            return const SizedBox.shrink();
                          }

                          final visibleMarkers = allSpots.where(
                                (spot) => _mapctl.camera.visibleBounds
                                .contains(spot.mapMarker.point),
                          ).toList();

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _spotsNotifier.value = visibleMarkers.length;
                            }
                          });

                          // if (visibleMarkers.isEmpty) {
                          //   return Image.asset('Assets/Images/pin.gif', scale: 5);
                          // }
                          if (visibleMarkers.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_outlined, size: 64, color: Colors.blue[200]),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Quiet area!",
                                      style: GoogleFonts.robotoSlab(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "No spots reported nearby. If you're leaving a spot, help others by declaring it!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.01,
                            ),
                            itemCount: visibleMarkers.length,
                            itemBuilder: (context, index) {
                              final parkingMarker = visibleMarkers[index];

                              final distance = userLocation == null
                                  ? 0.0
                                  : _calculateDistance(parkingMarker.mapMarker.point);

                              final age = DateTime.now()
                                  .difference(parkingMarker.timestamp!);

                              return ParkingSpotTile(
                                distanceMeters: distance,
                                age: age,
                                probability: parkingMarker.probability,
                                reportCount: parkingMarker.reports,
                                activeSearchers: searchingCount,
                                onTap: () {
                                  _mapctl.move(
                                    parkingMarker.mapMarker.point,
                                    18.0,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            )

                ],
              ),
            ),
          ),
        ));
  }

  void _showCurrentOrCustomLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset('Assets/Images/circleArea.png',
                        scale: 7, fit: BoxFit.cover)),
                const SizedBox(height: 10),
                const Text(
                  "We will create a circle to determine the area of priority. Do you want to use your current location as a center point for the circle or set a custom location?",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _parkingService.addSearching(_currentLocation);
                HiveService("").setPremiumSearchStateToCache(true);
                //radarVisibility.value = true;
                Navigator.of(context).pop();
              },
              child: const Text(
                "Current Location",
                style: TextStyle(color: Colors.blueAccent, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Custom Location",
                style: TextStyle(color: Colors.blueAccent, fontSize: 16),
              ),
            )
          ],
        );
      },
    );
  }
}
