import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:parkingmap/model/latlng_bounds_model.dart';
import 'package:parkingmap/model/location.dart';
import 'package:parkingmap/model/marker_model.dart';
import 'package:parkingmap/screens/declare.dart';
import 'package:parkingmap/screens/enable_location.dart';
import 'package:parkingmap/screens/login.dart';
import 'package:parkingmap/screens/unsupported_location.dart';
import 'package:parkingmap/services/marker_event_bus.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:vibration/vibration.dart';
import 'screens/home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:parkingmap/model/pushnotification_model.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert' as cnv;
import 'dart:convert';
import 'screens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'tools/app_config.dart';
import 'package:provider/provider.dart';
import 'package:parkingmap/services/hive_service.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  Hive.registerAdapter(MarkerModelAdapter());
  Hive.registerAdapter(LatLngBoundsModelAdapter());
  await Hive.openBox<List>("markersBox");
  await Hive.openBox("cacheBox");
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(ChangeNotifierProvider(
    create: (context) => LocationProvider(),
    child: const MyApp(),
  ));
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //NotificationController.createNewNotification();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
        child: MaterialApp(
      title: 'pasthelwparking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  // #region declarations
  PushNotification? notification;
  String? token, address, fcmtoken;
  DateTime? notifReceiveTime;
  double height = 100;

  double width = 100;

  double latitude = 0, longitude = 0;

  int index = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  late Future _getPosition;

  OverlayState? overlayState;

  bool? entered;
  //late SharedPreferences prefs;
  String? email;

  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  String? serviceStatusValue;

  List<Widget> screens = [];
  int selectedIndex = 0;

  List<Marker> markers = [];
  LatLngBounds? currentBounds;

  bool? _isUserLogged;
  bool shouldUpdate = false;

  bool permissionsNotGranted = false;
  String permissionToastTitle = "", permissionToastBody = "";

  late PageController _pageViewController;
  final ValueNotifier<int> _notifier = ValueNotifier(0);
  ValueNotifier<double> notifierImageScale = ValueNotifier(15);

  final markersBox = "markersBox";
  final cacheBox = "cacheBox";
  // #endregion

// Function to check if current camera bounds are within expanded bounds
  bool isWithinExpandedBounds(
      LatLngBounds currentBounds, LatLngBounds expandedBounds) {
    // Check if the current bounds fit within the expanded bounds
    return (currentBounds.southWest.latitude >=
            expandedBounds.southWest.latitude &&
        currentBounds.southWest.longitude >=
            expandedBounds.southWest.longitude &&
        currentBounds.northEast.latitude <= expandedBounds.northEast.latitude &&
        currentBounds.northEast.longitude <=
            expandedBounds.northEast.longitude);
  }

  Future<List<Marker>> updateBounds(
      LatLngBounds bounds, double currentZoom) async {
    var cachedMarkers = await HiveService(markersBox).getAllCachedMarkers();
    var expandedBounds =
        await HiveService(cacheBox).getExpandedBoundsFromCache();
    if ((cachedMarkers.isEmpty && shouldUpdate) ||
        expandedBounds == null ||
        !isWithinExpandedBounds(bounds, expandedBounds) ||
        shouldUpdate) {
      shouldUpdate = false;
      postNewVisibleBounds(
          bounds.southWest.latitude,
          bounds.southWest.longitude,
          bounds.northEast.latitude,
          bounds.northEast.longitude,
          email);
      // Fetch markers asynchronously
      var updatedMarkers = await getMarkersInBounds(bounds, currentZoom);
      var mappedMarkers = updatedMarkers.map((marker) {
        return MarkerModel(
            latitude: marker.point.latitude,
            longitude: marker.point.longitude,
            width: marker.width,
            height: marker.height,
            alignment: marker.alignment,
            rotate: marker.rotate);
      }).toList();
      await HiveService(markersBox).deleteAllCachedMarkers();
      await HiveService(markersBox).addMarkersToCache(mappedMarkers);
      await HiveService(cacheBox).addExpandedBoundsToCache(bounds);
      return updatedMarkers;
    }
    List<Marker> mrkList = List.empty(growable: true);
    for (var cmrk in cachedMarkers) {
      mrkList.add((cmrk as MarkerModel).toMarker());
    }
    return mrkList;
    //   return cachedMarkers.map((marker) {
    //     return Marker(
    //         point: LatLng(marker.latitude, marker.longitude),
    //         child: Image.asset('Assets/Images/parking-location.png', scale: 18));
    //   }).toList();
  }

  Future<Response?> postNewVisibleBounds(
      swLat, swLong, neLat, neLong, userid) async {
    try {
      var response = await http.post(
          Uri.parse('${AppConfig.instance.apiUrl}/update-bounds'),
          body: cnv.jsonEncode({
            "email": email,
            "sw_lat": swLat.toString(),
            "sw_long": swLong.toString(),
            "ne_lat": neLat.toString(),
            "ne_long": neLong.toString()
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

  Future<List<Marker>> getMarkersInBounds(
      LatLngBounds bounds, double currentZoom) async {
    try {
      final url =
          '${AppConfig.instance.apiUrl}/markers?swLat=${bounds.southWest.latitude}&swLng=${bounds.southWest.longitude}&neLat=${bounds.northEast.latitude}&neLng=${bounds.northEast.longitude}';

      final response = await http.get(Uri.parse(url),
          headers: {"Authorization": globals.securityToken!});

      if (response.statusCode == 200) {
        List<dynamic> markersData = json.decode(response.body);
        // Manually create Marker objects from the response
        List<Marker> markers = markersData.map((data) {
          return Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(data['latitude'], data['longitude']),
            child: Image.asset('Assets/Images/parking-location.png', scale: 18),
          );
        }).toList();

        return markers;
      } else {
        globals.showServerErrorToast(context);
        return List.empty();
      }
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return List.empty();
    }
  }

  Future registerNotification() async {
    // 1. Initialize the Firebase app
    //await Firebase.initializeApp();
    // 2. Instantiate Firebase Messaging
    bool? vibrationEnabled = await Vibration.hasVibrator();

    // 3. On iOS, this helps to take the user permissions
    // NotificationSettings settings = await _messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   provisional: false,
    //   sound: true,
    // );
    //if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // For handling the received notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Parse the message received
      notifReceiveTime = DateTime.now();
      //postInsertTime();
      notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
      );
      if (notification != null) {
        var update = bool.parse(message.data['update']);
        var points = int.tryParse(message.data['points']);
        if (points != null) {
          var type = message.data['type'].toString();
          if (type == "addPoints") {
            HiveService("").addPointsToCache(points.toString());
          } else {}
        }
        if (update) {
          shouldUpdate = true;
        } else {
          var type = message.data['type'].toString();
          latitude = double.parse(message.data['lat']);
          longitude = double.parse(message.data['long']);
          if (type == "add") {
            MarkerEventBus().addMarker(LatLng(latitude, longitude));
            if (vibrationEnabled!) {
              Vibration.vibrate();
            }
          } else {
            MarkerEventBus().deleteMarker(LatLng(latitude, longitude));
          }
        }
      }
    });
    // } else {
    //   var error = 'User declined or has not accepted notification permission';
    //   FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
    // }
  }

  Future notificationsCount() async {
    if (screens.isEmpty) {
      screens.add(HomePage(address, updateBounds));
      screens.add(DeclareSpotScreen(token: token.toString()));
      screens.add(const SettingsScreen());
    }
  }

  // postInsertTime() async {
  //   try {
  //     var response = await http.post(
  //         //Uri.parse("http://192.168.1.26:8080/pasthelwparking/searching.php"), //vm
  //         Uri.parse("https://pasthelwparkingv1.000webhostapp.com/php/insert_time.php"),
  //         body: {"time": '$notifReceiveTime', "uid": '$token'});
  //     print(response.body);
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  // getUserID() async {
  //   try {
  //     email = AuthService().email;
  //     var response = await http.post(
  //         Uri.parse("${AppConfig.instance.apiUrl}/get-userid"),
  //         body: cnv.jsonEncode({"email": email.toString()}),
  //         headers: {
  //           "Content-Type": "application/json",
  //           "Authorization": globals.securityToken!
  //         });
  //     if (response.body.isNotEmpty) {
  //       var decoded = cnv.jsonDecode(response.body);
  //       token = decoded["user_id"];
  //     }
  //   } catch (e) {
  //     return e.toString();
  //   }
  // }

  Future updateUserID() async {
    try {
      var userID = await AuthService().getCurrentUserUID();
      var email = AuthService().email ?? "";
      http.put(Uri.parse("${AppConfig.instance.apiUrl}/update-userid"),
          body: cnv.jsonEncode({"user_id": userID.toString(), "email": email}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future registerFcmToken() async {
    try {
      token = await AuthService().getCurrentUserUID();
      await _getDevToken();
      var userId = token;
      http.post(Uri.parse("${AppConfig.instance.apiUrl}/register-fcmToken"),
          body: cnv.jsonEncode(
              {"user_id": userId.toString(), "fcmtoken": fcmtoken.toString()}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  checkForInitialState() async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? initialMessage) {
      if (initialMessage != null) {
        //NotificationController.createNewNotification();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    requirePermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (permissionsNotGranted) {
        toastification.show(
            context: context,
            type: ToastificationType.warning,
            style: ToastificationStyle.flat,
            title: Text(permissionToastTitle),
            description: Text(permissionToastBody),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 4),
            animationBuilder: (
              context,
              animation,
              alignment,
              child,
            ) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            borderRadius: BorderRadius.circular(100.0),
            boxShadow: lowModeShadow,
            showProgressBar: false);
        //return;
      }
    });
    //NotificationController.startListeningNotificationEvents();
    // app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      registerFcmToken();
    });
    //when app is terminated
    checkForInitialState();
    Provider.of<LocationProvider>(context, listen: false).onLocationUpdated =
        (newLocation) {};
    Provider.of<LocationProvider>(context, listen: false).initializeLocation();
    _isUserLogged = AuthService().isUserLogged();
    WidgetsBinding.instance.addObserver(this);
    _getPosition = _determinePosition();
    registerNotification();
    overlayState = Overlay.of(context);
    _toggleServiceStatusStream();
    _pageViewController = PageController(initialPage: selectedIndex);
    shouldUpdate = true;
  }

  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    _pageViewController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // These are the callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        // widget is resumed
        if (serviceStatusValue != null && serviceStatusValue != 'enabled') {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const EnableLocation()),
              (Route route) => false);
        }
        break;
      case AppLifecycleState.inactive:
        // widget is inactive
        break;
      case AppLifecycleState.paused:
        // widget is paused
        break;
      case AppLifecycleState.detached:
        // widget is detached
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
        _serviceStatusStreamSubscription?.cancel();
        _serviceStatusStreamSubscription = null;
      }).listen((serviceStatus) {
        if (serviceStatus == ServiceStatus.enabled) {
          updateStatus('enabled');
        } else {
          updateStatus('disabled');
        }
      });
    }
  }

  void updateStatus(String value) {
    if (serviceStatusValue != value) {
      setState(() {
        serviceStatusValue = value;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (BuildContext context) => super.widget));
      });
    }
  }

  void requirePermissions() async {
    try {
      // Request location permission first
      var locationStatus = await ph.Permission.location.request();
      if (locationStatus.isDenied) {
        permissionToastTitle = "Location Permissions Needed";
        permissionToastBody = "Please grant location permissions.";
        permissionsNotGranted = true;
        return;
      }

      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Then request notification permission
          var notificationStatus = await ph.Permission.notification.request();
          if (notificationStatus.isDenied) {
            permissionToastTitle = "Notification Permissions Needed";
            permissionToastBody = "Please grant notification permissions.";
            permissionsNotGranted = true;
            return;
          }
        }
      }

      // If both permissions are granted, set permissionsNotGranted to false
      permissionsNotGranted = false;
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future _determinePosition() async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceStatusValue = 'disabled';
      return Future.error('Location services are disabled.');
    } else {
      serviceStatusValue = 'enabled';
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    Position position =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    if (!(position.latitude >= 40.5530246503162 &&
        position.latitude <= 40.6600 &&
        position.longitude >= 22.87426837242212 &&
        position.longitude <= 22.9900)) {
      return Future.error('Location out of bounds');
    }
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        address =
            "${place.locality}, ${place.subLocality},${place.street}, ${place.postalCode}";
      });
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future sharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //await prefs.clear();
    entered = prefs.getBool("isLoggedIn");
  }

  Future _getDevToken() async {
    fcmtoken = await FirebaseMessaging.instance.getToken();
  }

  Future appInitializations() async {
    //await requirePermissions();
    await _getPosition;
    await globals.initializeSecurityToken();
    await globals.initializePoints();
    await globals.initializePremiumSearchState();
    updateUserID();
    registerFcmToken();
    notificationsCount();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    if (_isUserLogged == null || !_isUserLogged!) {
      return const LoginPage();
    } else {
      return FutureBuilder(
          future: Future.wait([appInitializations()]),
          builder: (context, snapshot) {
            // Future done with no errors
            if (snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError) {
              return Scaffold(
                body: PageView(
                  controller: _pageViewController,
                  physics: const ClampingScrollPhysics(),
                  children: screens,
                  onPageChanged: (changedIndex) {
                    _notifier.value = changedIndex;
                  },
                ),
                bottomNavigationBar: ValueListenableBuilder(
                    valueListenable: _notifier,
                    builder: (BuildContext context, int value, Widget? child) {
                      return BottomNavigationBar(
                        // iconSize: iconsSize,
                        unselectedItemColor: Colors.blue[900],
                        backgroundColor: Colors.white,
                        items: [
                          BottomNavigationBarItem(
                            icon: SizedBox(
                              height: screenHeight * 0.03,
                              child: const Icon(Icons.map),
                            ),
                            label: 'Map',
                          ),
                          BottomNavigationBarItem(
                            icon: SizedBox(
                              height: screenHeight * 0.03,
                              child: const Icon(Icons.add_location_alt),
                            ),
                            label: 'Declare',
                          ),
                          BottomNavigationBarItem(
                            icon: SizedBox(
                              height: screenHeight * 0.03,
                              child: const Icon(Icons.settings),
                            ),
                            label: 'Settings',
                          ),
                        ],
                        currentIndex: _notifier.value,
                        onTap: (index) {
                          _notifier.value = index;
                          _pageViewController.animateToPage(_notifier.value,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.ease);
                        },
                        selectedIconTheme: IconThemeData(
                          color: const Color.fromARGB(255, 0, 140,
                              255), // change color of the selected icon
                          // size:
                          //     selectedIconSize, // change size of the selected icon
                        ),
                      );
                    }),
              );
            }
            // Future with some errors
            else if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasError) {
              if (snapshot.error == 'Location out of bounds') {
                return const UnsupportedLocation();
              }
              return const EnableLocation();
            } else {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 1.5,
                    height: MediaQuery.of(context).size.width / 1.5,
                    child: const CircularProgressIndicator(
                      strokeWidth: 10,
                      backgroundColor: Colors.white,
                      color: Colors.blue,
                    ),
                  ),
                ),
              );
            }
          });
    }
  }
}
