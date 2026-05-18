import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/reservation/reservation_step1.dart';
import '../screens/profile/profile_screen.dart';
import '../core/services/cart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/notification_helper.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNav({super.key, this.selectedIndex = 0});

  static Widget buildCartFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
        },
        backgroundColor: AppColors.secondary,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 3),
        ),
        elevation: 8,
        child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15), 
      height: 60, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_rounded, 'ACCUEIL', 0),
          _buildNavItem(context, Icons.restaurant_menu_rounded, 'MENU', 1),
          // Central space for FAB with label
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Text(
              'PANIER',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildNavItem(context, Icons.calendar_today_rounded, 'RÉSERVATION', 2),
          _buildNavItem(context, Icons.person_rounded, 'PROFIL', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () async {
        if (isSelected) return;

        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email');
        final isRealClient = userEmail != null && userEmail.isNotEmpty;

        if (index == 0) {
          Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomeScreen(), transitionDuration: Duration.zero));
        } else if (index == 1) {
          final sessionToken = CartService().sessionToken;
          final etablissementId = CartService().etablissementId;
          if (etablissementId != null) {
            Navigator.pushReplacement(
              context, 
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => MenuScreen(
                  etablissementId: etablissementId,
                  sessionToken: sessionToken,
                ), 
                transitionDuration: Duration.zero
              )
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez scanner le QR de votre table pour voir le menu.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else if (index == 2) {
          if (isRealClient) {
            Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ReservationStep1(), transitionDuration: Duration.zero));
          } else {
            NotificationHelper.showWarning(
              context, 
              title: "Accès limité", 
              message: "Veuillez créer un compte pour pouvoir réserver."
            );
          }
        } else if (index == 3) {
          if (isRealClient) {
            Navigator.pushReplacement(
              context, 
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ProfileScreen(),
                transitionDuration: Duration.zero
              )
            );
          } else {
            NotificationHelper.showWarning(
              context, 
              title: "Accès limité", 
              message: "Veuillez créer un compte pour accéder à votre profil."
            );
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.secondary : Colors.grey.shade700,
            size: 22, // Slightly smaller icons for thinner nav
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.secondary : Colors.grey.shade700,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
