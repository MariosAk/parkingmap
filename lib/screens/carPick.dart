import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parkingmap/main.dart';
import 'dart:convert' as cnv;

import 'package:parkingmap/tools/app_config.dart';

class Car {
  Image image;
  String carType;
  Car(this.image, this.carType);
}

class CarPick extends StatefulWidget {
  final String? email;
  const CarPick(this.email, {super.key});
  @override
  _CarPickState createState() => _CarPickState();
}

class _CarPickState extends State<CarPick> {
  int tappedIndex = 100;
  List<bool> borders = [];

  registerCar(String carType, String? email) async {
    try {
      var response = await http.post(
          Uri.parse("${AppConfig.instance.apiUrl}/register-car"),
          body: cnv.jsonEncode({"carType": carType, "email": email}),
          headers: {"Content-Type": "application/json"});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Car> carList = [
      Car(
          Image(
            image: const AssetImage('Assets/Images/Sedan.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Sedan'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/Coupe.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Coupe'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/Pickup.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Pickup'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/Jeep.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Jeep'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/Wagon.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Wagon'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/Crossover.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Crossover'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/Hatchback.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Hatchback'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/Van.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Van'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/SportCoupe.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'Sportcoupe'),
      Car(
          Image(
            image: const AssetImage('Assets/Images/SUV.png'),
            width: MediaQuery.of(context).size.width / 4,
            height: MediaQuery.of(context).size.height / 4,
          ),
          'SUV'),
    ];

    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
            Color(0xFF6190e8),
            Color(0xFFa7bfe8),
            Color(0xFFc8d9e8)
          ])),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text("Pick your car type"),
            centerTitle: true,
          ),
          body: Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: ListView.builder(
                itemCount: carList.length,
                itemBuilder: (context, index) {
                  borders.add(false);
                  return GestureDetector(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: tappedIndex == index
                            ? Border.all(color: Colors.white, width: 3.0)
                            : Border.all(
                                color: Colors.transparent,
                              ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: carList[index].image,
                    ),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: MediaQuery.of(context).size.height / 4,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                      'You picked ${carList[index].carType} cartype.'),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      backgroundColor: Colors.white,
                                      shadowColor: Colors.grey,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32.0)),
                                      minimumSize: const Size(100, 40),
                                    ),
                                    onPressed: () => () {
                                      Navigator.pop(context);
                                      registerCar(
                                          carList[index].carType, widget.email);
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const MyHomePage()));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Registration completed.")));
                                    }(),
                                    child: const Text('Continue'),
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        backgroundColor: Colors.white,
                                        shadowColor: Colors.grey,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(32.0)),
                                        minimumSize: const Size(100, 40),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Back'))
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      setState(() {
                        tappedIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
