import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:parkingmap/screens/claim.dart';
import 'package:parkingmap/screens/declare.dart';
import 'package:parkingmap/screens/enableLocation.dart';
import 'package:parkingmap/screens/login.dart';
import 'package:parkingmap/screens/unsupported_location.dart';
import 'package:parkingmap/services/MarkerEventBus.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/push_notification_service.dart';
import 'screens/home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:parkingmap/model/pushnotificationModel.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert' as cnv;
import 'dart:convert';
import 'screens/settings.dart';
import 'services/SqliteService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'tools/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await NotificationController.initializeLocalNotifications();
  runApp(const MyApp());
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message");
  NotificationController.createNewNotification();
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
      //home: MyDatabase(),
      //home: IntroScreen(),
    ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  //initialize firebase values
  late final FirebaseMessaging _messaging;
  PushNotification? notification;
  String? token, address, fcm_token;
  DateTime? notifReceiveTime;
  Position? _currentPosition;
  double height = 100;

  double width = 100;

  double latitude = 0, longitude = 0;

  int index = 0, count = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  late Future _getPosition;

  OverlayState? overlayState;

  SqliteService sqliteService = SqliteService();

  bool? entered;
  //late SharedPreferences prefs;
  String? email;

  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  late String serviceStatusValue;

  List<Widget> screens = [];
  int selectedIndex = 0;

  List<Marker> markers = [];
  LatLngBounds? currentBounds;

  bool? _isUserLogged;

  Future<List<Marker>> updateBounds(LatLngBounds bounds) async {
    postNewVisibleBounds(bounds.southWest.latitude, bounds.southWest.longitude,
        bounds.northEast.latitude, bounds.northEast.longitude, email);
    // Fetch markers asynchronously
    var updatedMarkers = await getMarkersInBounds(bounds);
    return updatedMarkers;
  }

  postNewVisibleBounds(swLat, swLong, neLat, neLong, userid) async {
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
      var data = response.body;
      return data;
    } catch (e) {
      print(e);
    }
  }

  Future<List<Marker>> getMarkersInBounds(LatLngBounds bounds) async {
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
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40.0,
            ),
          );
        }).toList();

        return markers;
      } else {
        throw Exception('Failed to load markers');
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  void registerNotification() async {
    // 1. Initialize the Firebase app
    await Firebase.initializeApp();
    // 2. Instantiate Firebase Messaging
    _messaging = FirebaseMessaging.instance;

    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
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
          latitude = double.parse(message.data['lat']);
          longitude = double.parse(message.data['long']);
          MarkerEventBus().addMarker(LatLng(latitude, longitude));
          HapticFeedback.mediumImpact();
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future notificationsCount() async {
    count = await SqliteService().getNotificationCount();
    screens.add(HomePage(address, token, _currentPosition!.latitude,
        _currentPosition!.longitude, count, markers, updateBounds));
    screens.add(DeclareSpotScreen(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        token: token.toString()));
    screens.add(SettingsScreen());
  }

  postInsertTime() async {
    try {
      var response = await http.post(
          //Uri.parse("http://192.168.1.26:8080/pasthelwparking/searching.php"), //vm
          Uri.parse("https://pasthelwparkingv1.000webhostapp.com/php/insert_time.php"),
          body: {"time": '$notifReceiveTime', "uid": '$token'});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  getUserID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      email = prefs.getString("email");
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/get-userid"),
          body: cnv.jsonEncode({"email": email.toString()}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
      if (response.body.isNotEmpty) {
        var decoded = cnv.jsonDecode(response.body);
        token = decoded["user_id"];
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future registerFcmToken() async {
    try {
      await getUserID();
      await _getDevToken();
      var userId = token;
      http.post(Uri.parse("${AppConfig.instance.apiUrl}/register-fcmToken"),
          body: cnv.jsonEncode({
            "user_id": userId.toString(),
            "fcm_token": fcm_token.toString()
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": globals.securityToken!
          });
    } catch (e) {}
  }

  checkForInitialState() async {
    //await Firebase.initializeApp();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? initialMessage) {
      print('initialMessage data: ${initialMessage?.data}');
      if (initialMessage != null) {
        // PushNotification notification = PushNotification(
        //   title: initialMessage.notification?.title,
        //   body: initialMessage.notification?.body,
        // );
        NotificationController.createNewNotification();
      }
    });
  }

  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    // app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ClaimPage(
              int.parse(message.data["latestLeavingID"]),
              message.data["user_id"],
              double.parse(message.data["lat"]),
              double.parse(message.data["long"]),
              message.data["cartype"],
              int.parse(message.data["times_skipped"]),
              message.data["time"])));
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    //when app is terminated
    checkForInitialState();

    super.initState();
    _isUserLogged = AuthService().isUserLogged();
    // FirebaseAuth.instance.authStateChanges().listen((User? user) {
    //   if (user == null) {
    //     setState(() {
    //       entered = false; // User is signed out
    //     });
    //     print("User is currently signed out!");
    //   } else {
    //     setState(() {
    //       entered = true; // User is signed out
    //     });
    //     print("User is signed in!");

    //     // Update the UI or redirect as needed
    //   }
    // });
    WidgetsBinding.instance.addObserver(this);
    _getPosition = _determinePosition();
    registerNotification();
    overlayState = Overlay.of(context);
    _toggleServiceStatusStream();
  }

  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // These are the callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        // widget is resumed
        print("???resumed");
        // if (serviceStatusValue == 'enabled') {
        //   Navigator.of(context).pushAndRemoveUntil(
        //       MaterialPageRoute(builder: (context) => const MyHomePage()),
        //       (Route route) => false);
        // } else {
        //   Navigator.of(context).pushAndRemoveUntil(
        //       MaterialPageRoute(builder: (context) => const EnableLocation()),
        //       (Route route) => false);
        // }
        break;
      case AppLifecycleState.inactive:
        // widget is inactive
        print("???inactive");
        break;
      case AppLifecycleState.paused:
        // widget is paused
        print("???paused");
        break;
      case AppLifecycleState.detached:
        // widget is detached
        print("???detached");
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
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

  Future _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceStatusValue = 'disabled';
      return Future.error('Location services are disabled.');
    } else {
      serviceStatusValue = 'enabled';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // if (!(position.latitude >= 40.5530246503162 &&
    //     position.latitude <= 40.6600 &&
    //     position.longitude >= 22.87426837242212 &&
    //     position.longitude <= 22.9900)) {
    //   return Future.error('Location out of bounds');
    // }
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentPosition = position;
        address =
            "${place.locality}, ${place.subLocality},${place.street}, ${place.postalCode}";
        print("///// $address");
      });
    } catch (e) {
      print(e);
    }
  }

  Future sharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //await prefs.clear();
    entered = prefs.getBool("isLoggedIn");
  }

  Future _getDevToken() async {
    fcm_token = await FirebaseMessaging.instance.getToken();
    print("DEV TOKEN FIREBASE CLOUD MESSAGING -> $fcm_token");
  }

  @override
  Widget build(BuildContext context) {
    if (_isUserLogged == null || !_isUserLogged!) {
      return const LoginPage();
    } else {
      return FutureBuilder(
          future: Future.wait([
            _getPosition,
            globals.initializeSecurityToken(),
            registerFcmToken(),
            notificationsCount()
          ]),
          builder: (context, snapshot) {
            // Future done with no errors
            if (snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError) {
              return Scaffold(
                body: screens[selectedIndex],
                bottomNavigationBar: BottomNavigationBar(
                  selectedItemColor: Colors.blue,
                  backgroundColor: Colors.white,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.map),
                      label: 'Map',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add_location_alt),
                      label: 'Declare',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
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
                body: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 1.5,
                    height: MediaQuery.of(context).size.width / 1.5,
                    child: const CircularProgressIndicator(strokeWidth: 10),
                  ),
                ),
              );
            }
          });
    }
  }
  // @override
  // Widget build(BuildContext context) {
  //   return StreamBuilder<User?>(
  //     stream: FirebaseAuth.instance.authStateChanges(),
  //     builder: (context, authSnapshot) {
  //       if (authSnapshot.connectionState == ConnectionState.active) {
  //         if (authSnapshot.hasData) //user is signed in
  //         {
  //           return FutureBuilder(
  //               future: Future.wait(
  //                   [_getPosition, registerFcmToken(), notificationsCount()]),
  //               builder: (context, snapshot) {
  //                 // Future done with no errors
  //                 if (snapshot.connectionState == ConnectionState.done &&
  //                     !snapshot.hasError) {
  //                   // if (entered == null || entered == false) {
  //                   //   return const LoginPage();
  //                   //} else {
  //                   return Scaffold(
  //                     body: screens[selectedIndex],
  //                     bottomNavigationBar: BottomNavigationBar(
  //                       selectedItemColor: Colors.blue,
  //                       backgroundColor: Colors.white,
  //                       items: const [
  //                         BottomNavigationBarItem(
  //                           icon: Icon(Icons.map),
  //                           label: 'Map',
  //                         ),
  //                         BottomNavigationBarItem(
  //                           icon: Icon(Icons.add_location_alt),
  //                           label: 'Declare',
  //                         ),
  //                         BottomNavigationBarItem(
  //                           icon: Icon(Icons.settings),
  //                           label: 'Settings',
  //                         ),
  //                       ],
  //                       currentIndex: selectedIndex,
  //                       onTap: (index) {
  //                         setState(() {
  //                           selectedIndex = index;
  //                         });
  //                       },
  //                     ),
  //                   );
  //                 }
  //                 //}

  //                 // Future with some errors
  //                 else if (snapshot.connectionState == ConnectionState.done &&
  //                     snapshot.hasError) {
  //                   if (snapshot.error == 'Location out of bounds') {
  //                     return const UnsupportedLocation();
  //                   }
  //                   return const EnableLocation();
  //                 } else {
  //                   return Scaffold(
  //                     body: Center(
  //                       child: SizedBox(
  //                         width: MediaQuery.of(context).size.width / 1.5,
  //                         height: MediaQuery.of(context).size.width / 1.5,
  //                         child:
  //                             const CircularProgressIndicator(strokeWidth: 10),
  //                       ),
  //                     ),
  //                   );
  //                 }
  //               });
  //         } else {
  //           return const LoginPage();
  //         }
  //       } else {
  //         // While waiting for authentication state
  //         return Scaffold(
  //           body: Center(
  //             child: SizedBox(
  //               width: MediaQuery.of(context).size.width / 1.5,
  //               height: MediaQuery.of(context).size.width / 1.5,
  //               child: const CircularProgressIndicator(strokeWidth: 10),
  //             ),
  //           ),
  //         );
  //       }
  //     },
  //   );
  // }
}
