import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:parkingmap/model/pushnotificationModel.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkingmap/services/MarkerEventBus.dart';
import 'package:parkingmap/tools/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as cnv;
import 'package:badges/badges.dart' as bdg;
import 'package:parkingmap/screens/notifications_page.dart' as notificationPage;
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

class HomePage extends StatefulWidget {
  String? address, token;
  double latitude;
  double longitude;
  int notificationCount;
  List<Marker> markers;
  Function(LatLngBounds, double) updateBounds;
  HomePage(this.address, this.token, this.latitude, this.longitude,
      this.notificationCount, this.markers, this.updateBounds,
      {super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  PushNotification? notification;
  String? token, address;
  DateTime? notifReceiveTime;
  double height = 100;

  double width = 100;

  int index = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  bool leaving = false;

  bool isSelected = false;
  double? containerHeight, containerWidth, x, y;

  String ApiKey = 'AIzaSyBghQsgXKFjMw5LG79JTmLNgibSc2atYZM';
  String TomTomApiKey = 'qa5MzxXesmBUxRLaWQnFRmMZ2D33kE7b';
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
  LatLng? savedMapPosition = null;

  bool isMapInitialized = false;

  final ValueNotifier<List<Marker>> _markersNotifier =
      ValueNotifier<List<Marker>>([]);

  final PopupController _popupController = PopupController();

  Card card = const Card();
  bool convertedToAddress = false;

  Map<LatLng, String> _addressCache = {};

  late StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentLocation;
  bool _shouldCenterOnLocation = false;

  double _zoom = 20;

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    timer.cancel();
    subscription?.cancel();
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
      //for (int i = 0; i < initialMarkers.length; i++) {}
      addMarker(initialMarkers);
      subscription = _mapctl.mapEventStream.listen((MapEvent mapEvent) async {
        if (mapEvent is MapEventMoveEnd) {
          // Perform actions when the map movement ends
          var newPositionMarkers = await widget.updateBounds(
              _mapctl.camera.visibleBounds, _mapctl.camera.zoom);
          addMarker(newPositionMarkers);
        }
      });
    });

    // Listen to marker events from the event bus
    MarkerEventBus().markerStream.listen((LatLng markerPosition) {
      Marker mrk = Marker(
        width: 80.0,
        height: 80.0,
        point: markerPosition,
        child: Image.asset('Assets/Images/parking-location.png', scale: 15),
      );
      List<Marker> markers = [mrk];
      addMarker(markers);
      convertPointToAddress(markerPosition);
    });

    //updateLocation();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulsatingAnimation =
        Tween<double>(begin: 0, end: 20).animate(_animationController);
    timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      setState(() {
        value = (value + 1) % 100;
      });
    });
  }

  Future<String?> convertPointToAddress(LatLng marker) async {
    try {
      //if (!convertedToAddress) {
      convertedToAddress = true;
      var response = await http.get(Uri.parse(
          'https://api.tomtom.com/maps/orbis/places/reverseGeocode/${marker.latitude},${marker.longitude}.json?key=$TomTomApiKey&apiVersion=1'));
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

  void addMarker(List<Marker> newMarkers) {
    bool exists = _markersNotifier.value.any((existingMarker) {
      return newMarkers.any((marker) => marker.point == existingMarker.point);
    });
    if (!exists) {
      _markersNotifier.value = List.from(_markersNotifier.value)
        ..addAll(newMarkers);
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
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return; // Exit if the service is not enabled
      }
    }

    // Check if permission is granted
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return; // Exit if permission is not granted
      }
    }

    // Subscribe to location updates
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = currentLocation;
        LatLng currentLatLng =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        pulsatingMarkerPosition = currentLatLng;
        // Move the map to the user's current position
        if (_shouldCenterOnLocation) {
          _mapctl.move(currentLatLng, 18.0);
        }
      });
    });
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapctl.move(
          new LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          18.0); // Center map on current location
    } else {
      // Handle the case where currentPosition is still null
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to get current location. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    var spots = _markersNotifier.value
        .where((element) => LatLngBounds(_mapctl.camera.visibleBounds.southWest,
                _mapctl.camera.visibleBounds.northEast)
            .contains(element.point))
        .length;
    return Container(
        color: Colors.white,
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: Text(
                "ParkingMap",
                style: GoogleFonts.robotoSlab(
                    textStyle: const TextStyle(color: Colors.black)),
              ),
              automaticallyImplyLeading: false,
              centerTitle: false,
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
                            height: MediaQuery.of(context).size.height / 2.5,
                            width: MediaQuery.of(context).size.width,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: FlutterMap(
                                  mapController: _mapctl,
                                  options: MapOptions(
                                      initialCenter: savedMapPosition == null
                                          ? LatLng(
                                              widget.latitude, widget.longitude)
                                          : LatLng(savedMapPosition!.latitude,
                                              savedMapPosition!.longitude),
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
                                            "com.example.parkingmap"),
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
                                                (event, selectedMarkers) {},
                                            //     selectedMarkerBuilder:
                                            //         (BuildContext context,
                                            //             Marker marker) {
                                            //       // Check if the address is already in the cache
                                            //       if (_addressCache
                                            //           .containsKey(marker.point)) {
                                            //         // If cached, return the cached address immediately
                                            //         var cachedAddress =
                                            //             _addressCache[marker.point];
                                            //         var decodedData = cnv
                                            //             .jsonDecode(cachedAddress!);
                                            //         var address =
                                            //             decodedData["addresses"][0]
                                            //                     ["address"]
                                            //                 ["streetNameAndNumber"];
                                            //         return Card(
                                            //           child: Padding(
                                            //             padding:
                                            //                 const EdgeInsets.all(
                                            //                     4.0),
                                            //             child: Column(
                                            //               mainAxisSize:
                                            //                   MainAxisSize.min,
                                            //               children: [
                                            //                 Text(
                                            //                   address,
                                            //                   style: const TextStyle(
                                            //                       fontSize: 10,
                                            //                       fontWeight:
                                            //                           FontWeight
                                            //                               .bold),
                                            //                 ),
                                            //               ],
                                            //             ),
                                            //           ),
                                            //         );
                                            //       } else {
                                            //         // If not cached, fetch the address and cache it
                                            //         return FutureBuilder(
                                            //           future: Future.wait([
                                            //             convertPointToAddress(
                                            //                 marker.point)
                                            //           ]),
                                            //           builder: (context, snapshot) {
                                            //             if (snapshot
                                            //                     .connectionState ==
                                            //                 ConnectionState
                                            //                     .waiting) {
                                            //               return const Card(
                                            //                 child: Padding(
                                            //                   padding:
                                            //                       EdgeInsets.all(
                                            //                           4.0),
                                            //                   child:
                                            //                       CircularProgressIndicator(),
                                            //                 ),
                                            //               ); // Show loading while fetching the address
                                            //             } else if (snapshot
                                            //                 .hasError) {
                                            //               return const Card(
                                            //                 child: Padding(
                                            //                   padding:
                                            //                       EdgeInsets.all(
                                            //                           4.0),
                                            //                   child: Text(
                                            //                       'Error fetching address'),
                                            //                 ),
                                            //               );
                                            //             } else {
                                            //               return const Card(
                                            //                 child: Padding(
                                            //                   padding:
                                            //                       EdgeInsets.all(
                                            //                           4.0),
                                            //                   child: Text(
                                            //                       'No address found'),
                                            //                 ),
                                            //               );
                                            //             }
                                            //           },
                                            //         );
                                            //       }
                                            //     },
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
                                fontSize: 20),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    )),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Available spots: $spots",
                    style: GoogleFonts.robotoSlab(
                        textStyle: TextStyle(color: Colors.blue[900]),
                        fontWeight: FontWeight.w900,
                        fontSize: 20),
                    textAlign: TextAlign.left,
                  ),
                  Expanded(
                      child: spots > 0
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 15.0,
                                          vertical:
                                              5.0), // Margin around the card
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
                                              const SizedBox(
                                                  width:
                                                      15), // Space between icon and text
                                              Expanded(
                                                child: Text(
                                                  '$address',
                                                  style: const TextStyle(
                                                    fontSize:
                                                        16, // Larger font size
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
}
