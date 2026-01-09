import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/main.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  IntroScreenState createState() => IntroScreenState();
}

class IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // --- CUSTOM COMPONENT: ANIMATED SEARCH VISUAL ---
  Widget _buildSearchVisual() {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (index) => _buildExpandingCircle(index * 0.3)),
          const Icon(Icons.location_searching_rounded, size: 80, color: Colors.blueAccent),
        ],
      ),
    );
  }

  // --- CUSTOM COMPONENT: ANIMATED REWARD VISUAL ---
  Widget _buildRewardVisual() {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withOpacity(0.1),
            ),
          ),
          const Icon(Icons.stars_rounded, size: 100, color: Colors.amber),
          ...List.generate(5, (index) {
            final angle = (index * 72) * (math.pi / 180);
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(math.cos(angle) * (60 + (10 * _pulseController.value)),
                      math.sin(angle) * (60 + (10 * _pulseController.value))),
                  child: const Icon(Icons.add, size: 20, color: Colors.amberAccent),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // --- CUSTOM COMPONENT: ANIMATED SAFETY VISUAL ---
  Widget _buildSafetyVisual() {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.shutter_speed_rounded, size: 140, color: Colors.blueGrey),
          Positioned(
            bottom: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text("SAFETY FIRST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandingCircle(double delay) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double progress = (_pulseController.value + delay) % 1.0;
        return Container(
          width: 100 + (150 * progress),
          height: 100 + (150 * progress),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blueAccent.withOpacity(1.0 - progress),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageDecoration = PageDecoration(
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A237E),
      ),
      bodyTextStyle: GoogleFonts.poppins(fontSize: 16.0, color: Colors.black54),
      pageColor: Colors.white,
      imagePadding: const EdgeInsets.only(top: 40),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: IntroductionScreen(
        globalBackgroundColor: Colors.white,
        pages: [
          PageViewModel(
            title: "Discover empty spots!",
            body: "Stop circling. See real-time available spots shared by the community.",
            image: _buildSearchVisual(),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Earn Rewards",
            body: "Declare your spot when leaving to earn points and gain priority access.",
            image: _buildRewardVisual(),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Always drive safe",
            body: "Keep your eyes on the road. We'll handle the maps and notifications.",
            image: _buildSafetyVisual(),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _finishIntro(context),
        onSkip: () => _finishIntro(context),
        showSkipButton: true,
        skip: Text("Skip", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
        next: const Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent),
        done: Text("Start", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(22.0, 10.0),
          activeColor: Colors.blueAccent,
          color: Colors.black12,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
        ),
      ),
    );
  }

  void _finishIntro(context) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
            (Route route) => false);
  }
}
