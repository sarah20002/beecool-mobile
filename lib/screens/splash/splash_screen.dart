import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/bee_logo.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 4), () {});
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background Hexagons
          Positioned(
            top: 80, 
            left: -40, 
            child: Opacity(opacity: 0.15, child: _buildHexagon(140, AppColors.secondary))
          ),
          Positioned(
            top: 250, 
            right: -60, 
            child: Opacity(opacity: 0.12, child: _buildHexagon(180, AppColors.secondary))
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding: Bee Illustration + Beeكول
                FadeInDown(
                  duration: const Duration(seconds: 1),
                  child: const BeeIllustration(height: 120),
                ),
                const SizedBox(height: 40),
                FadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: const BeeTextLogo(fontSize: 48, color: Colors.white),
                ),
                
                const SizedBox(height: 14),
                const Text(
                  'RESTAURANT · مطعم',
                  style: TextStyle(color: AppColors.secondary, fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Bottom progress
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 3,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FadeInLeft(
                      duration: const Duration(seconds: 3),
                      child: Container(
                        width: 80, 
                        height: 3,
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'CHARGEMENT...',
                  style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexagon(double size, Color color) {
    return Transform.rotate(
      angle: 0.5,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.2)),
      ),
    );
  }
}
