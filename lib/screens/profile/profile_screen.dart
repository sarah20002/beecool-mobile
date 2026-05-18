import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../reservation/reservation_history_screen.dart';
import '../cart/order_history_screen.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Yasmine Bennis';
  String _userEmail = 'yasmine@beecool.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('user_nom') ?? '';
    final prenom = prefs.getString('user_prenom') ?? '';
    final email = prefs.getString('user_email') ?? '';
    
    if (nom.isNotEmpty || prenom.isNotEmpty) {
      setState(() {
        _userName = '$prenom $nom'.trim();
        if (email.isNotEmpty) {
          _userEmail = email;
        }
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable Body ──
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100), // padding for bottom nav
            child: Column(
              children: [
                // Golden-Orange Gradient Header
                _buildHeader(),
                
                const SizedBox(height: 65), // spacing for stats card overlap

                // Menu items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.calendar_today_rounded,
                        iconColor: AppColors.secondary,
                        bgColor: AppColors.secondary.withOpacity(0.12),
                        title: 'Mes réservations',
                        subtitle: '2 à venir',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReservationHistoryScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.shopping_bag_outlined,
                        iconColor: Colors.blue,
                        bgColor: Colors.blue.withOpacity(0.12),
                        title: 'Historique de commandes',
                        subtitle: '24 commandes',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.favorite_border_rounded,
                        iconColor: Colors.brown.shade400,
                        bgColor: Colors.brown.shade100.withOpacity(0.4),
                        title: 'Mes favoris',
                        subtitle: '8 plats',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.credit_card_rounded,
                        iconColor: AppColors.success,
                        bgColor: AppColors.success.withOpacity(0.12),
                        title: 'Moyens de paiement',
                        subtitle: 'Visa •• 4128',
                        onTap: () {},
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Modern Pill Logout Button
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEF), // light soft red
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Se déconnecter',
                                style: TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stats Card Overlay (overlapping header and body) ──
          Positioned(
            top: 250,
            left: 20,
            right: 20,
            child: _buildStatsCard(),
          ),

          // ── Floating Cart FAB ──
          Positioned(
            bottom: 35,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: CustomBottomNav.buildCartFAB(context),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    );
  }

  Widget _buildHeader() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      height: 290,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD200), // Warm yellow-gold
            Color(0xFFF7971E), // Vibrant amber-orange
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Subtle circular background elements
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.03),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top row: Back button, Title, Settings button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button circular glass effect
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
                      ),
                    ),
                    
                    const Text(
                      'Profil',
                      style: TextStyle(
                        color: Color(0xFF0F172A), // Dark text for bright background
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    // Light/Dark Theme icon button circular glass effect
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFF0F172A), size: 16),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),

                // Avatar with capsule ★ OR Badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.amber.shade200,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'Y',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1128), // Deep dark blue capsule
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Name Yasmine Bennis
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Color(0xFF0F172A), // Dark text for readability
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                
                const SizedBox(height: 6),

                // Member Tier capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'MEMBRE OR • DEPUIS 2024',
                    style: TextStyle(
                      color: Color(0xFF5C3F00), // Dark gold/bronze font
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA), // Warm light-ivory background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('12', 'RÉSERVATIONS'),
          Container(height: 35, width: 1, color: Colors.grey.withOpacity(0.15)),
          _buildStatItem('320', "GOÛTS D'OR"),
          Container(height: 35, width: 1, color: Colors.grey.withOpacity(0.15)),
          _buildStatItem('4,9', 'SATISFACTION'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            val,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7E7260), // Dark grey
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ),
      ),
    );
  }
}
