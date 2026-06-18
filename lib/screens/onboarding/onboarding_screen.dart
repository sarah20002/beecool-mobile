import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/bee_logo.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Image de fond avec overlay sombre
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo et flèche en haut
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: FadeInDown(
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BeeIllustration(height: 35),
                              SizedBox(width: 10),
                              BeeTextLogo(fontSize: 20, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Textes de bienvenue
                  FadeInLeft(
                    child: const Text(
                      'BIENVENUE',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: const Text(
                      'Une table.\nUne histoire.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        fontFamily: 'Serif',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 400),
                    child: const Text(
                      'Réservez, commandez et vivez l\'expérience gastronomique signée par notre Chef.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Boutons en bas
                  Row(
                    children: [
                      Expanded(
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 15), // Reduced padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25), // Adjusted border radius for smaller button
                              ),
                            ),
                            child: const Text(
                              'Commencer',
                              style: TextStyle(
                                fontSize: 16, // Reduced font size
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
