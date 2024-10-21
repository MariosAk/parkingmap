import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parkingmap/screens/parking_location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:parkingmap/tools/app_config.dart';

class ClaimPage extends StatefulWidget {
  Map? data;
  final String carType, userID, time;
  final int latestLeavingID, times_skipped;
  final double latitude, longitude;
  ClaimPage(this.latestLeavingID, this.userID, this.latitude, this.longitude,
      this.carType, this.times_skipped, this.time,
      {super.key});
  @override
  _ClaimPageState createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  OverlayState? overlayState;
  double progress = 0, count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    overlayState = Overlay.of(context);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        count += 0.1;
        if (count >= 6) {
          _timer?.cancel();
          // Do something here, such as showing a success message or navigating to the next screen
          globals.postSkip(widget.times_skipped + 1, widget.time,
              widget.latitude, widget.longitude, widget.latestLeavingID);
          Navigator.pop(context, 'close');
        }
      });
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (_timer!.isActive) {
        setState(() {
          progress = 1;
        });
      }
    });
    //_determinePosition();
    //registerNotification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  postClaim() async {
    globals.searching = false;
    try {
      var response = await http
          .post(Uri.parse("${AppConfig.instance.apiUrl}/set-claimedby"),
              body: cnv.jsonEncode({
                "latestLeavingID": widget.latestLeavingID.toString(),
                "claimedby_id": widget.userID
              }),
              headers: {"Content-Type": "application/json"});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    //OverlayEntry? overlayEntry;
    //overlayEntry = OverlayEntry(builder: (context) {
    // to be displayed on the Overlay
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.45),
      body: Stack(
        children: <Widget>[
          Center(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.all(Radius.circular(40))),
              margin: const EdgeInsets.only(left: 10, right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 15, top: 10),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(minutes: 1),
                        builder: (BuildContext context, double value,
                            Widget? child) {
                          return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 6.0,
                              color: Colors.red);
                        },
                      ),
                    ),
                  ),
                  if (widget.carType == "Sedan")
                    Image.asset('Assets/Images/Sedan.png')
                  else if (widget.carType == "Coupe")
                    Image.asset('Assets/Images/Coupe.png')
                  else if (widget.carType == "Pickup")
                    Image.asset('Assets/Images/Pickup.png')
                  else if (widget.carType == "Jeep")
                    Image.asset('Assets/Images/Jeep.png')
                  else if (widget.carType == "Wagon")
                    Image.asset('Assets/Images/Wagon.png')
                  else if (widget.carType == "Crossover")
                    Image.asset('Assets/Images/Crossover.png')
                  else if (widget.carType == "Hatchback")
                    Image.asset('Assets/Images/Hatchback.png')
                  else if (widget.carType == "Van")
                    Image.asset('Assets/Images/Van.png')
                  else if (widget.carType == "Sportcoupe")
                    Image.asset('Assets/Images/SportCoupe.png')
                  else if (widget.carType == "SUV")
                    Image.asset('Assets/Images/SUV.png')
                  else
                    Image.asset('Assets/Images/Sedan.png'),
                  Text("A parking spot is free for you to claim!",
                      style: GoogleFonts.openSans(
                          textStyle: const TextStyle(color: Colors.black),
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  TextButton(
                    child: Text("Claim",
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w600,
                        )),
                    onPressed: () {
                      postClaim();
                      _timer?.cancel();
                      //globals.cancelSearch();
                      Navigator.pop(context, 'close');
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ParkingLocation(
                              widget.times_skipped,
                              widget.data,
                              widget.latitude,
                              widget.longitude,
                              widget.userID,
                              widget.latestLeavingID)));
                    },
                  ),
                  TextButton(
                    child: Text("Not for me",
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w600,
                        )),
                    onPressed: () {
                      _timer?.cancel();
                      globals.postSkip(
                          widget.times_skipped + 1,
                          widget.time,
                          widget.latitude,
                          widget.longitude,
                          widget.latestLeavingID);
                      Navigator.pop(context, 'close');
                      //setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
