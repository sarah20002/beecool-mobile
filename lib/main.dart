import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Stripe avec mon clé publique
  Stripe.publishableKey = 'pk_test_51RiZXzIraeYRmqZ7m8aOd8HIngmOSqt0sadXU3e6IpPKr4DCTFbp8CgjOXiuR5RKRxziTCSMQnRsPf2ku1o8bphM00cSHYAYkR';
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeCool Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
