import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:parkingmap/model/location.dart';
import 'package:parkingmap/model/marker_model.dart';
import 'package:parkingmap/model/pushnotification_model.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/globals.dart';
import 'package:parkingmap/services/hive_service.dart';
import 'package:parkingmap/services/marker_event_bus.dart';
import 'dart:convert' as cnv;
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:parkingmap/services/parking_service.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:parkingmap/tools/radar_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';

import '../dependency_injection.dart';
import '../tools/parkingspottile_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // #region variables
  final ParkingService _parkingService = getIt<ParkingService>();
  PushNotification? notification;
  String? address;
  DateTime? notifReceiveTime;
  double height = 100;

  double width = 100;

  int index = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  bool leaving = false;

  bool isSelected = false;
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

  Card card = const Card();
  bool convertedToAddress = false;

  late StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentLocation;
  LatLng? previousLocation;
  bool _shouldCenterOnLocation = true;

  double _zoom = 20;
  String cellTopic = "";
  late ValueNotifier<bool> radarVisibility;

  final ValueNotifier<LatLng?> _userLocationNotifier = ValueNotifier<LatLng?>(null);

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
    _userLocationNotifier.dispose(); // You missed this one
    radarVisibility.dispose(); // You missed this one
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    startLocationTracking();
    // Wait until the widget tree is fully built before listening to map events
    //WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await widget.updateBounds(
      //    _mapctl.camera.visibleBounds, _mapctl.camera.zoom);
      //addMarker(initialMarkers);
      //subscription = _mapctl.mapEventStream.listen((MapEvent mapEvent) async {
      //  if (mapEvent is MapEventMoveEnd) {
      //    _shouldCenterOnLocation = false;
      //    updateBoundsAddMarkers();
      //  }
      //});
    //});

    // Listen to marker events from the event bus
    //MarkerEventBus().markerStream.listen((MarkerEvent markerEvent) {
    //  if (markerEvent.type == MarkerEventType.add) {
    //    Marker mrk = Marker(
    //      width: 80.0,
    //      height: 80.0,
    //      point: markerEvent.position,
    //      child: Image.asset('Assets/Images/parking-location.png', scale: 15),
    //    );
    //    List<Marker> markers = [mrk];
    //    addMarker(markers);
    //    //convertPointToAddress(markerEvent.position);
    //  } else if (markerEvent.type == MarkerEventType.delete) {
    //    deleteMarkerReceived(markerEvent.position);
    //  }
    //});

    previousLocation = LatLng(
        Provider.of<LocationProvider>(context, listen: false)
            .currentLocation!
            .latitude!,
        Provider.of<LocationProvider>(context, listen: false)
            .currentLocation!
            .longitude!);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulsatingAnimation =
        Tween<double>(begin: 0, end: 20).animate(_animationController);
    // timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
    //   setState(() {
    //     value = (value + 1) % 100;
    //   });
    // });

    radarVisibility = ValueNotifier<bool>(globals.premiumSearchState);
  }

  //Future updateBoundsAddMarkers() async {
    /*await widget.updateBounds(
       _mapctl.camera.visibleBounds, _mapctl.camera.zoom);*/
   // addMarker(_parkingService.markersNotifier.value);
  //}

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
      MarkerModel markerModel = MarkerModel(
          latitude: spot.mapMarker.point.latitude,
          longitude: spot.mapMarker.point.longitude,
          width: spot.mapMarker.width,
          height: spot.mapMarker.height,
          alignment: spot.mapMarker.alignment,
          rotate: spot.mapMarker.rotate);
      await HiveService("markersBox").deleteCachedMarker(spot);
    }
  }

  // Method to initialize and start location tracking
  void startLocationTracking() async {
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
      if (oldTopic != cellTopic &&
          (previousLocation == null || _calculateDistance(currentLatLng) > 500.0)) {
        if (oldTopic.isNotEmpty) {
          await FirebaseMessaging.instance.unsubscribeFromTopic(oldTopic);
        }
        await FirebaseMessaging.instance
            .subscribeToTopic(cellTopic)
            .catchError((error) {});
      }
      _currentLocation = currentLocation;

      if (currentLatLng.latitude != previousLocation!.latitude &&
          currentLatLng.longitude != previousLocation!.longitude) {
        //pulsatingMarkerPosition = currentLatLng;
        _userLocationNotifier.value = currentLatLng;
        // Move the map to the user's current position
        if (_shouldCenterOnLocation &&
            (previousLocation == null || _calculateDistance(currentLatLng) > 5.0)) {
          _mapctl.move(currentLatLng, 18.0);
        }
        //updateBoundsAddMarkers();
        pulsatingMarkerPosition = currentLatLng;
        previousLocation = currentLatLng;
      }
    });
  }

  String calculateCellTopic(double latitude, double longitude) {
    const gridCellSize = 0.05;
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
           _mapctl.camera.visibleBounds!, _mapctl.camera.zoom);
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

    double distance = FlutterMapMath.distanceBetween(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
        marker.point.latitude,
        marker.point.longitude,
        "meters");
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
    _parkingService.deleteMarker(marker, cellTopic).then(
      (value) {
        if (value != null && value.statusCode == 200) {
          globals.showSuccessfullToast(context, "Spot was deleted.");
        } else {
          globals.showServerErrorToast(context);
        }
      },
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
    const int freshLimitMinutes = 10;   // 0-10 mins: Green
    const int mediumLimitMinutes = 30;  // 10-30 mins: Yellow
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
    double multiplierList = shortestSide >= 600 ? 0.02 : 0.035;
    double addressTextSize = screenWidth * multiplier;
    double sizedboxSize = screenHeight * 0.015;
    double listTextSize = screenWidth * multiplierList;
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
                children: [
                  // Left-side title
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "ParkingMap",
                      style: GoogleFonts.robotoSlab(
                        textStyle:
                            const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: radarVisibility,
                    builder: (context, value, child) {
                      return Visibility(
                        visible: radarVisibility.value,
                        replacement: const Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 50, // Same size as the radar widget
                              height: 50, // Same size as the radar widget
                            ),
                          ),
                        ),
                        child:
                            // Spacer to push radar widget to center
                            const Expanded(
                          child: Center(
                            child: RotatingRadarWidget(
                              size: 50,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Right-side actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _purchasePriorityPrompt(context);
                        },
                        child:
                            Image.asset('Assets/Images/reward.png', scale: 15),
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
                                        print("Map is now ready. Performing initial fetch.");
                                        _parkingService.updateBounds(
                                            _mapctl.camera.visibleBounds!, _mapctl.camera.zoom);
                                        subscription = _mapctl.mapEventStream.listen((MapEvent mapEvent) {
                                          if (mapEvent is MapEventMoveEnd) {
                                            _shouldCenterOnLocation = false;
                                            // When the user stops moving the map, just tell the service to update.
                                            // That's its only job.
                                            print("Map move ended. Requesting update from service.");
                                            _parkingService.updateBounds(
                                                mapEvent.camera.visibleBounds!, mapEvent.camera.zoom);
                                          }
                                        });
                                        isMapInitialized = true;
                                        pulsatingMarkerPosition =
                                            _mapctl.camera.center;
                                      },
                                      onPositionChanged:
                                          (position, hasGesture) {
                                        _zoom = (5 +
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
                                    // CircleLayer(
                                    //   circles: [
                                    //     CircleMarker(
                                    //       point: LatLng(40.629485,
                                    //           22.948015), // Center of the circle
                                    //       color: Colors.blue.withOpacity(
                                    //           0.3), // Fill color with opacity
                                    //       borderStrokeWidth: 2.0,
                                    //       borderColor:
                                    //           Colors.blue, // Border color
                                    //       useRadiusInMeter:
                                    //           true, // Use radius in meters
                                    //       radius: 500, // Radius in meters
                                    //     ),
                                    //   ],
                                    // ),
                                    if (isMapInitialized)
                                      AnimatedBuilder(
                                        // 1. It listens to your existing animation controller.
                                        animation: _animationController,

                                        // 2. This builder function re-runs on every animation "tick".
                                        builder: (context, child) {
                                          // Safety check: Don't try to draw if we don't have a location yet.
                                          if (pulsatingMarkerPosition == null) {
                                            return const SizedBox.shrink();
                                          }

                                          // 3. It returns a MarkerLayer, which knows how to position itself on the map.
                                          return MarkerLayer(
                                            markers: [
                                              // This is the outer, pulsating, transparent circle.
                                              Marker(
                                                // We use the animation's value directly for the size.
                                                // We add `_zoom` to it, just like in your original code.
                                                width: _pulsatingAnimation.value + _zoom,
                                                height: _pulsatingAnimation.value + _zoom,
                                                // We give it a geographic LatLng point. The map handles the rest.
                                                point: pulsatingMarkerPosition!,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    // Your original color logic.
                                                    color: Colors.blue.withOpacity(0.3),
                                                  ),
                                                ),
                                              ),

                                              // This is the inner, solid, main location dot.
                                              Marker(
                                                width: _zoom, // Your original size logic.
                                                height: _zoom, // Your original size logic.
                                                point: pulsatingMarkerPosition!,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.blue,
                                                    // Your original border logic.
                                                    border: Border.all(color: Colors.white, width: 3),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    Positioned(
                                      bottom: 20,
                                      right: 20,
                                      child: FloatingActionButton(
                                        onPressed: _centerOnCurrentLocation,
                                        backgroundColor: Colors.white70,
                                        child: const Icon(
                                          Icons.my_location,
                                        ),
                                      ),
                                    ),
                                    ValueListenableBuilder<List<ParkingSpotData>>(
                                      valueListenable: _parkingService.markersNotifier,
                                      builder: (context, parkingSpots, child) {
                                        print("UI is rebuilding with ${parkingSpots.length} markers.");
                                        //final mapMarkers = parkingSpots.map((spot) => spot.mapMarker).toList();
                                        final mapMarkers = parkingSpots.map((spot) {

                                          // 1. Calculate the color dynamically
                                          final age = DateTime.now().difference(spot.timestamp!);
                                          final statusColor = getAgeColor(age);

                                          // 2. Return a new Marker with the composite UI (Icon + Dot)
                                          return Marker(
                                            point: spot.mapMarker.point,
                                            width: 80.0, // Keep consistent with your original size
                                            height: 80.0,
                                            // Use a Stack to overlay the dot on top of the image
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Layer A: The original parking icon
                                                //Image.asset('Assets/Images/parking-location.png', scale: 18),

                                                // Layer B: The TTL Indicator Dot
                                                Positioned(
                                                  top: 15, // Adjust these values to position the dot exactly where you want
                                                  right: 20,
                                                  child: Container(
                                                    width: 14,
                                                    height: 14,
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
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList();
                                        return PopupMarkerLayer(
                                          options: PopupMarkerLayerOptions(
                                            markers: mapMarkers,
                                            popupController: _popupController,
                                            onPopupEvent:
                                                (event, selectedMarkers) {
                                              if (selectedMarkers.isNotEmpty) {
                                                // Assuming you want to show the dialog for the first selected marker
                                                Marker selectedMarker =
                                                    selectedMarkers.first;

                                                // Show the AlertDialog when the popup is tapped
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext
                                                          context) =>
                                                      _showMarkAsTakenDialog(
                                                          context,
                                                          selectedMarker),
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
                          builder: (context, userLocation, child) {
                            return ValueListenableBuilder<List<ParkingSpotData>>(
                              valueListenable: _parkingService.markersNotifier,
                              builder: (context, allSpots, child) {
                                if (!isMapInitialized) {
                                  // If the map isn't ready, we can't calculate visible markers.
                                  // It's safe to return an empty container or a loading indicator.
                                  // This prevents the crash on the first frame.
                                  return const SizedBox
                                      .shrink(); // Or a loading spinner
                                }
                                // 1. Pre-filter the markers that are visible on the map
                                final visibleMarkers = allSpots.where((
                                    spot) =>
                                    _mapctl.camera.visibleBounds.contains(
                                        spot.mapMarker.point)).toList();
                                WidgetsBinding.instance.addPostFrameCallback((
                                    _) {
                                  if (mounted) {
                                    _spotsNotifier.value =
                                        visibleMarkers.length;
                                  }
                                });

                                if (visibleMarkers.isEmpty) {
                                  return Image.asset(
                                      'Assets/Images/pin.gif', scale: 5);
                                }

                                // 2. Build the ListView only with the visible markers
                                return ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.01),
                                  itemCount: visibleMarkers.length,
                                  itemBuilder: (context, index) {
                                    final parkingMarker = visibleMarkers[index];
                                    try {
                                      final double distance;
                                      if (userLocation == null) {
                                        distance = 0.0;
                                      } else {
                                        distance = _calculateDistance(userLocation);
                                      }

                                      final age = DateTime.now().difference(parkingMarker.timestamp!);

                                      // 4. Return the ParkingSpotTile with the real-time distance.
                                      return ParkingSpotTile(
                                        distanceMeters: distance,
                                        age: age,
                                        probability: parkingMarker.probability,
                                        onTap: () {
                                          _mapctl.move(parkingMarker.mapMarker.point, 18.0);
                                        },
                                      );
                                    } catch (e) {
                                      // Log the error for debugging purposes
                                      print(
                                          "Error processing address for marker: $e");
                                      return const SizedBox
                                          .shrink(); // Use SizedBox.shrink() instead of Container()
                                    }
                                  },
                                );
                              },
                            );
                          }),
                  )

                ],
              ),
            ),
          ),
        ));
  }

  Widget _showMarkAsTakenDialog(BuildContext context, Marker marker) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Visual Icon Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.beenhere_rounded, // Represents verification/completion
                size: 40,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Title
            Text(
              "Spot Taken?",
              style: GoogleFonts.robotoSlab(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Description text
            const Text(
              "Thanks for keeping the map updated! Confirming this will remove the marker for all users.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // 4. Buttons Row
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      markSpotAsTaken(marker);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Confirm",
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                radarVisibility.value = true;
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
