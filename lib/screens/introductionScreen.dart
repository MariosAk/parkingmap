import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:parkingmap/main.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Widget _buildFullscreenImage() {
    return Image.asset(
      'assets/fullscreen.jpg',
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      alignment: Alignment.center,
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('Assets/Images/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    PageDecoration pageDecoration = const PageDecoration(
      pageColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
      ),
    );
    return Container(
        color: Colors.white,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text("ParkingApp"),
            centerTitle: true,
          ),
          body: Center(
            child: IntroductionScreen(
              globalBackgroundColor: Colors.white,
              pages: [
                PageViewModel(
                  title: "Discover empty parking spots with ease!",
                  body:
                      "Searching endless hours for a parking spot is no more. Pasthelwparking does it for you.",
                  image: _buildImage(
                      'carParkbutton.png', MediaQuery.of(context).size.width),
                  decoration: pageDecoration,
                ),
                PageViewModel(
                  title: "Save time, spend it in something you love.",
                  body:
                      "Instead of spending your time searching, do something you like. Don't worry.. We keep an eye for you.",
                  image: _buildImage('time.png'),
                  decoration: pageDecoration,
                ),
                PageViewModel(
                  title: "Always take care!",
                  body:
                      "This is not an excuse to be on the phone..Keep your eyes on the road.",
                  image: _buildImage('crash.png'),
                  decoration: pageDecoration,
                ),

                //add more screen here
              ],
              onDone: () {
                // When done button is press
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                    (Route route) => false);
              },
              onSkip: () {
                // You can also override onSkip callback
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                    (Route route) => false);
              },
              showBackButton: false,
              showSkipButton: true,
              skip: const Icon(Icons.skip_next),
              next: const Icon(Icons.arrow_right),
              done: const Text("Done",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              dotsDecorator: DotsDecorator(
                  size: const Size.square(10.0),
                  activeSize: const Size(20.0, 10.0),
                  //activeColor: theme.accentColor,
                  color: Colors.black26,
                  spacing: const EdgeInsets.symmetric(horizontal: 3.0),
                  activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0)),
                  activeColor: Colors.blue),
            ),
          ),
        )));
  }
}
