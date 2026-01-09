import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkingmap/services/globals.dart' as globals;
import 'package:toastification/toastification.dart';

import '../dependency_injection.dart';
import '../services/user_service.dart';

class PremiumShowcaseScreen extends StatelessWidget {
  PremiumShowcaseScreen({super.key});
  final UserService _userService = getIt<UserService>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                "ParkingMap Premium",
                style: GoogleFonts.robotoSlab(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Upgrade to the ultimate parking experience.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Features List
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFeatureItem(Icons.block, "No Ads", "Clean, distraction-free map interface."),
                  _buildFeatureItem(Icons.radar, "Dynamic Radius", "Expand your search area up to 1.5km."),
                  _buildFeatureItem(Icons.sort, "Advanced Sorting", "Sort by distance, freshness, or reliability."),
                  _buildFeatureItem(Icons.visibility_off, "Smart Filtering", "Automatically hide low-confidence spots."),
                  _buildFeatureItem(Icons.verified, "Reliability Badge", "See verified status for every reported spot."),
                  _buildFeatureItem(Icons.notifications_active, "Background Alerts", "Get spot notifications even when the app is closed."),
                  _buildFeatureItem(Icons.psychology, "Pro AI Probability", "Calculated based on real-time device density."),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Discount Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      children: [
                        const TextSpan(text: "Early Adopter Discount: "),
                        TextSpan(
                          text: "€5.00",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red[300],
                          ),
                        ),
                        const TextSpan(
                          text: " €2.00/month",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CTA Button (The "Fake Door" Trigger)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () async {
                // LOG THE INTEREST HERE (Firebase Analytics etc)
                Navigator.pop(context);

                bool success = true;

                if (globals.sharedPreferences?.getBool('isInterestedInPremium') == null) {
                  success = await _userService.postInterestInPremium();
                }

                if(!context.mounted) return;

                if(success) {
                  globals.showSuccessfullToast(
                      context,
                      "Interest noted! You'll be notified when Premium launches."
                  );
                }
                else{
                  globals.showServerErrorToast(context);
                }
              },
              child: const Text(
                "I'm Interested - Get Discount",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue[900], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
