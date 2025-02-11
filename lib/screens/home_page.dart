import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:parkingmap/tools/app_config.dart';
import 'package:parkingmap/tools/radar_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';

class HomePage extends StatefulWidget {
  final String? address;
  final Function(LatLngBounds, double) updateBounds;
  const HomePage(this.address, this.updateBounds, {super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // #region variables
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

  String tomTomApiKey = 'qa5MzxXesmBUxRLaWQnFRmMZ2D33kE7b';
  final _controller = TextEditingController();
  String searchTxt = "";
  String lat = "";
  String lon = "";
  final MapController _mapctl = MapController();
  late StreamSubscription subscription;
  TextEditingController textController = TextEditingController();

  int value = 0;
  late Timer timer;
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

  final ValueNotifier<List<Marker>> _markersNotifier =
      ValueNotifier<List<Marker>>([]);

  final PopupController _popupController = PopupController();

  Card card = const Card();
  bool convertedToAddress = false;

  final Map<LatLng, String> _addressCache = {};

  late StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentLocation;
  LatLng? previousLocation;
  bool _shouldCenterOnLocation = true;

  double _zoom = 20;
  String cellTopic = "";
  late ValueNotifier<bool> radarVisibility;
  // #endregion

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    timer.cancel();
    subscription.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    startLocationTracking();
    // Wait until the widget tree is fully built before listening to map events
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<Marker> initialMarkers = await widget.updateBounds(
          _mapctl.camera.visibleBounds, _mapctl.camera.zoom);
      addMarker(initialMarkers);
      subscription = _mapctl.mapEventStream.listen((MapEvent mapEvent) async {
        if (mapEvent is MapEventMoveEnd) {
          _shouldCenterOnLocation = false;
          updateBoundsAddMarkers();
        }
      });
    });

    // Listen to marker events from the event bus
    MarkerEventBus().markerStream.listen((MarkerEvent markerEvent) {
      if (markerEvent.type == MarkerEventType.add) {
        Marker mrk = Marker(
          width: 80.0,
          height: 80.0,
          point: markerEvent.position,
          child: Image.asset('Assets/Images/parking-location.png', scale: 15),
        );
        List<Marker> markers = [mrk];
        addMarker(markers);
        //convertPointToAddress(markerEvent.position);
      } else if (markerEvent.type == MarkerEventType.delete) {
        deleteMarkerReceived(markerEvent.position);
      }
    });

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
    timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      setState(() {
        value = (value + 1) % 100;
      });
    });

    radarVisibility = ValueNotifier<bool>(globals.premiumSearchState);
  }

  Future<Response?> addSearching() async {
    try {
      var userId = await AuthService().getCurrentUserUID();
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/add-searching'),
          body: cnv.jsonEncode({
            "user_id": userId.toString(),
            "lat": _currentLocation!.latitude!.toString(),
            "long": _currentLocation!.longitude!.toString()
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

  Future updateBoundsAddMarkers() async {
    var newPositionMarkers = await widget.updateBounds(
        _mapctl.camera.visibleBounds, _mapctl.camera.zoom);
    addMarker(newPositionMarkers);
  }

  Future<String?> convertPointToAddress(LatLng marker) async {
    try {
      //if (!convertedToAddress) {
      convertedToAddress = true;
      var response = await http.get(Uri.parse(
          'https://api.tomtom.com/maps/orbis/places/reverseGeocode/${marker.latitude},${marker.longitude}.json?key=$tomTomApiKey&apiVersion=1'));
      if (response.statusCode == 200) {
        convertedToAddress = false;
        var decodedResponse = cnv.utf8.decode(response.bodyBytes);
        _addressCache[marker] = decodedResponse;
        return response.body;
      } else {
        return null;
      }
      //} else {
      //  return null;
      //}
    } catch (e) {
      return null;
    }
  }

  void deleteMarkerReceived(LatLng markerLatLng) async {
    bool exists = _markersNotifier.value.any((existingMarker) =>
        existingMarker.point.latitude == markerLatLng.latitude &&
        existingMarker.point.longitude == markerLatLng.longitude);
    if (exists) {
      var marker = _markersNotifier.value
          .where((existingMarker) =>
              existingMarker.point.latitude == markerLatLng.latitude &&
              existingMarker.point.longitude == markerLatLng.longitude)
          .first;
      _markersNotifier.value = List.from(_markersNotifier.value)
        ..remove(marker);
      MarkerModel markerModel = MarkerModel(
          latitude: marker.point.latitude,
          longitude: marker.point.longitude,
          width: marker.width,
          height: marker.height,
          alignment: marker.alignment,
          rotate: marker.rotate);
      await HiveService("markersBox").deleteCachedMarker(markerModel);
    }
  }

  Future<Response?> deleteMarker(Marker marker, String topic) async {
    try {
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/delete-marker"),
          body: cnv.jsonEncode({
            "latitude": marker.point.latitude.toString(),
            "longitude": marker.point.longitude.toString(),
            "topic": topic
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

  void addMarker(List<Marker> newMarkers) {
    bool exists = _markersNotifier.value.any((existingMarker) {
      return newMarkers.any((marker) => marker.point == existingMarker.point);
    });
    if (!exists) {
      _markersNotifier.value = List.from(_markersNotifier.value)
        ..addAll(newMarkers);
      var markerModels = _markersNotifier.value.map((newMarker) {
        return MarkerModel(
            alignment: newMarker.alignment,
            height: newMarker.height,
            width: newMarker.width,
            latitude: newMarker.point.latitude,
            longitude: newMarker.point.longitude,
            rotate: newMarker.rotate);
      }).toList();
      HiveService("markersBox").addMarkersToCache(markerModels);
    }
    for (Marker marker in newMarkers) {
      if (!_addressCache.keys.any((element) => marker.point == element)) {
        convertPointToAddress(marker.point);
      }
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
      cellTopic = calculateCellTopic(
          currentLocation.latitude!, currentLocation.longitude!);
      if (oldTopic != cellTopic) {
        if (oldTopic.isNotEmpty) {
          await FirebaseMessaging.instance.unsubscribeFromTopic(oldTopic);
        }
        await FirebaseMessaging.instance
            .subscribeToTopic(cellTopic)
            .catchError((error) {});
      }
      _currentLocation = currentLocation;
      LatLng currentLatLng =
          LatLng(currentLocation.latitude!, currentLocation.longitude!);
      if (currentLatLng.latitude != previousLocation!.latitude &&
          currentLatLng.longitude != previousLocation!.longitude) {
        pulsatingMarkerPosition = currentLatLng;
        // Move the map to the user's current position
        if (_shouldCenterOnLocation) {
          _mapctl.move(currentLatLng, 18.0);
        }
        updateBoundsAddMarkers();
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
      updateBoundsAddMarkers();
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
    FlutterMapMath flutterMapMath = FlutterMapMath();
    double distance = flutterMapMath.distanceBetween(
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
    deleteMarker(marker, cellTopic).then(
      (value) {
        if (value != null && value.statusCode == 200) {
          globals.showSuccessfullToast(context, "Spot was deleted.");
        } else {
          globals.showServerErrorToast(context);
        }
      },
    );
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
    var spots = _markersNotifier.value
        .where((element) => LatLngBounds(_mapctl.camera.visibleBounds.southWest,
                _mapctl.camera.visibleBounds.northEast)
            .contains(element.point))
        .length;
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
                                      _buildPulsatingMarker(),
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
                                    ValueListenableBuilder<List<Marker>>(
                                      valueListenable: _markersNotifier,
                                      builder: (context, markers, child) {
                                        return PopupMarkerLayer(
                                          options: PopupMarkerLayerOptions(
                                            markers: markers,
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
                        Container(
                          margin: const EdgeInsets.only(left: 15.0),
                          alignment: Alignment.topLeft,
                          child: Text(
                            widget.address!,
                            style: GoogleFonts.robotoSlab(
                                textStyle: TextStyle(color: Colors.blue[900]),
                                fontWeight: FontWeight.w600,
                                fontSize: addressTextSize),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    )),
                  ),
                  SizedBox(height: sizedboxSize),
                  Text(
                    "Available spots: $spots",
                    style: GoogleFonts.robotoSlab(
                        textStyle: TextStyle(color: Colors.blue[900]),
                        fontWeight: FontWeight.w900,
                        fontSize: addressTextSize),
                    textAlign: TextAlign.left,
                  ),
                  Expanded(
                      child: spots > 0
                          ? ListView.builder(
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01),
                              itemCount: _markersNotifier.value.length,
                              itemBuilder: (context, index) {
                                try {
                                  var latlong =
                                      _markersNotifier.value[index].point;
                                  if (LatLngBounds(
                                          _mapctl
                                              .camera.visibleBounds.southWest,
                                          _mapctl
                                              .camera.visibleBounds.northEast)
                                      .contains(latlong)) {
                                    var cachedAddress = _addressCache[latlong];
                                    var decodedData =
                                        cnv.jsonDecode(cachedAddress!);
                                    var address = decodedData["addresses"][0]
                                        ["address"]["streetNameAndNumber"];

                                    return Card(
                                      color: Colors.blue[50],
                                      margin: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.04,
                                          vertical: screenHeight *
                                              0.004), // Margin around the card
                                      elevation:
                                          4, // Elevation for shadow effect
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            15.0), // Rounded corners
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          var selectedMarker =
                                              _markersNotifier.value[index];
                                          _mapctl.move(
                                              selectedMarker.point, 18.0);
                                        },
                                        borderRadius: BorderRadius.circular(
                                            15.0), // Ensure the tap area matches the card shape
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              8.0), // Padding inside the card
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                  'Assets/Images/parking-location.png',
                                                  scale: 15),
                                              SizedBox(
                                                  width: screenWidth *
                                                      0.05), // Space between icon and text
                                              Expanded(
                                                child: Text(
                                                  '$address',
                                                  style: TextStyle(
                                                    fontSize:
                                                        listTextSize, // Larger font size
                                                    fontWeight: FontWeight
                                                        .bold, // Bold text
                                                    color: Colors
                                                        .black, // Text color
                                                  ),
                                                  overflow: TextOverflow
                                                      .ellipsis, // Handle long text
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  return Container(); // Return an empty container on error
                                }
                                return Container(); // Return an empty container if bounds are not matched
                              },
                            )
                          : Image.asset('Assets/Images/pin.gif', scale: 5))
                ],
              ),
            ),
          ),
        ));
  }

  Widget _showMarkAsTakenDialog(BuildContext context, Marker marker) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // Rounded corners
      ),
      backgroundColor: Colors.white, // Match the app's theme
      title: Text(
        "Declare Spot as Taken",
        style: GoogleFonts.robotoSlab(
          fontWeight: FontWeight.w600,
          color: Colors.blue[900],
        ),
      ),
      content: const Text(
        "Are you sure this spot is no longer available?",
        style: TextStyle(color: Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Dismiss dialog
          },
          child: Text(
            "Cancel",
            style: GoogleFonts.robotoSlab(
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            markSpotAsTaken(marker);
            Navigator.of(context).pop(); // Dismiss dialog
          },
          child: Text(
            "Confirm",
            style: GoogleFonts.robotoSlab(
              fontWeight: FontWeight.w500,
              color: Colors.blue[900],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsatingMarker() {
    final screenPoint =
        _mapctl.camera.latLngToScreenPoint(pulsatingMarkerPosition);
    return Positioned(
      top: screenPoint.y -
          (_pulsatingAnimation.value /
              2), // Update based on the map's projection
      left: screenPoint.x - (_pulsatingAnimation.value / 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulsatingAnimation,
            builder: (context, child) {
              return Container(
                width: _pulsatingAnimation.value + _zoom,
                height: _pulsatingAnimation.value + _zoom,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.3),
                ),
              );
            },
          ),
          Container(
            width: (_zoom),
            height: (_zoom),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ],
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
                addSearching();
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
