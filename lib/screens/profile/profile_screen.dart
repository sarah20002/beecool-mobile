import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/reservation_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/order_service.dart';
import '../auth/login_screen.dart';
import '../reservation/reservation_history_screen.dart';
import '../cart/order_history_screen.dart';
import 'favorites_screen.dart';
import 'reclamations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Yasmine Bennis';
  String _userEmail = 'yasmine@beecool.com';
  String _userNom = '';
  String _userPrenom = '';
  String _userPhone = '';
  int _pointsFidelite = 0;

  int _reservationsCount = 0;
  int _upcomingReservationsCount = 0;
  int _ordersCount = 0;
  int _favoritesCount = 0;
  int _memberSinceYear = 2024;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('user_nom') ?? '';
    final prenom = prefs.getString('user_prenom') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final telephone = prefs.getString('user_telephone') ?? '';
    final points = prefs.getInt('user_points') ?? 0;
    
    setState(() {
      _userNom = nom;
      _userPrenom = prenom;
      _userName = '$prenom $nom'.trim().isEmpty ? 'Yasmine Bennis' : '$prenom $nom'.trim();
      _userEmail = email.isEmpty ? 'yasmine@beecool.com' : email;
      _userPhone = telephone;
      _pointsFidelite = points;
    });

    _fetchLiveProfile();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final resList = await ReservationService().fetchUserReservations();
      int totalRes = resList.length;
      int upcomingRes = 0;
      int oldestYear = DateTime.now().year;
      bool hasValidYear = false;
      for (var res in resList) {
        final String dateHeureStr = res['dateHeure'] ?? '';
        if (dateHeureStr.isNotEmpty) {
          try {
            final dt = DateTime.parse(dateHeureStr);
            if (dt.year < oldestYear) {
              oldestYear = dt.year;
              hasValidYear = true;
            }
            final bool isPast = dt.isBefore(DateTime.now());
            final String apiStatut = res['statut']?.toString()?.toUpperCase() ?? '';
            if (apiStatut != 'ANNULEE' && apiStatut != 'ANNULE' && !isPast) {
              upcomingRes++;
            }
          } catch (_) {}
        }
      }
      if (mounted) {
        setState(() {
          _reservationsCount = totalRes;
          _upcomingReservationsCount = upcomingRes;
          if (hasValidYear) {
            _memberSinceYear = oldestYear;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading reservations count: $e");
    }

    try {
      final ordList = await OrderService().getClientOrders();
      if (mounted) {
        setState(() {
          _ordersCount = ordList.length;
        });
      }
    } catch (e) {
      debugPrint("Error loading orders count: $e");
    }

    try {
      final favList = await FavoritesService().getFavorites();
      if (mounted) {
        setState(() {
          _favoritesCount = favList.length;
        });
      }
    } catch (e) {
      debugPrint("Error loading favorites count: $e");
    }
  }

  Future<void> _fetchLiveProfile() async {
    try {
      final data = await AuthService().getProfile();
      if (data != null && mounted) {
        final nom = data['nom'] ?? '';
        final prenom = data['prenom'] ?? '';
        final email = data['email'] ?? '';
        final telephone = data['telephone'] ?? '';
        final points = data['pointsFidelite'] ?? 0;

        setState(() {
          _userNom = nom;
          _userPrenom = prenom;
          _userName = '$prenom $nom'.trim();
          _userEmail = email;
          _userPhone = telephone;
          _pointsFidelite = points;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement live du profil : $e');
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double pinThreshold = statusBarHeight + 64.0;
    double cardTop = 250.0 - _scrollOffset;
    if (cardTop < pinThreshold) {
      cardTop = pinThreshold;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable Body ──
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100), // padding for bottom nav
            child: Column(
              children: [
                // Golden-Orange Gradient Header
                _buildHeader(),
                
                const SizedBox(height: 65), // spacing for stats card overlap

                _buildFidelityCard(),

                const SizedBox(height: 10),

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
                        subtitle: '$_upcomingReservationsCount à venir',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReservationHistoryScreen()),
                          ).then((_) => _fetchStats());
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.shopping_bag_outlined,
                        iconColor: Colors.blue,
                        bgColor: Colors.blue.withOpacity(0.12),
                        title: 'Historique de commandes',
                        subtitle: '$_ordersCount commande${_ordersCount > 1 ? 's' : ''}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                          ).then((_) => _fetchStats());
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.favorite_border_rounded,
                        iconColor: Colors.brown.shade400,
                        bgColor: Colors.brown.shade100.withOpacity(0.4),
                        title: 'Mes favoris',
                        subtitle: '$_favoritesCount plat${_favoritesCount > 1 ? 's' : ''}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                          ).then((_) => _fetchStats());
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.support_agent_rounded,
                        iconColor: AppColors.error,
                        bgColor: AppColors.error.withOpacity(0.12),
                        title: 'Mes réclamations',
                        subtitle: 'Suivi de vos signalements',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReclamationsScreen()),
                          );
                        },
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
            top: cardTop,
            left: 20,
            right: 20,
            child: _buildStatsCard(),
          ),

        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
            Color(0xFFF59E0B), // Warm rich amber
            Color(0xFFD97706), // Deep rich gold/honey
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
          // Geometric decoration 1: Rotated Hexagon at top right
          Positioned(
            top: -40,
            right: -30,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
          ),

          // Geometric decoration 2: Rotated Hexagon at bottom left
          Positioned(
            bottom: -30,
            left: -40,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
            ),
          ),

          // Geometric decoration 3: Small diamond decoration
          Positioned(
            top: 80,
            left: 70,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top row: Back button, Title, Edit Profile button
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
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    
                    const Text(
                      'Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    // Edit Profile icon button circular glass effect
                    GestureDetector(
                      onTap: _showEditProfileBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),

                // Avatar with gold border
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFD200),
                            Color(0xFFF7971E),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: const NetworkImage(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150',
                        ),
                        backgroundColor: Colors.amber.shade200,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 10),
                            SizedBox(width: 2),
                            Text(
                              'OR',
                              style: TextStyle(
                                color: Color(0xFFD97706),
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
                    color: Colors.white,
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
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: Text(
                    'MEMBRE OR • DEPUIS $_memberSinceYear',
                    style: const TextStyle(
                      color: Color(0xFFFFD200),
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

  Widget _buildFidelityCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF132B49), // Deep slate-navy brand blue
            Color(0xFF0F172A), // Dark elegant slate
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Semi-transparent decorative circles
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          
          // Card Details
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARTE DE FIDÉLITÉ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BeeCool Gold Club'.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFFFD200), // Gold text
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.nfc_rounded,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ],
                ),
                
                // Chip Illustration
                Container(
                  width: 38,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'MEMBRE PRIVILÈGE',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'SOLDE DES POINTS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_pointsFidelite',
                              style: const TextStyle(
                                color: Color(0xFFFFD200), // Gold points
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Goûts d'Or",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
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
          _buildStatItem('$_reservationsCount', 'RÉSERVATIONS'),
          Container(height: 35, width: 1, color: Colors.grey.withOpacity(0.15)),
          _buildStatItem('$_pointsFidelite', "GOÛTS D'OR"),
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

  void _showEditProfileBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: _userNom);
    final prenomController = TextEditingController(text: _userPrenom);
    final emailController = TextEditingController(text: _userEmail);
    final phoneController = TextEditingController(text: _userPhone);
    final passwordController = TextEditingController();
    
    bool isSaving = false;
    bool obscurePassword = true;

    InputDecoration buildInputDeco({
      required String labelText,
      required IconData prefixIcon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF1F5F9).withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Modifier le profil',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.05),
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mettez à jour vos informations personnelles pour personnaliser votre expérience.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Avatar editing preview
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFFD200), Color(0xFFF7971E)],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundImage: const NetworkImage(
                                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150',
                                    ),
                                    backgroundColor: Colors.amber.shade100,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF132B49),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Fields Box with shadow and depth
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Prénom Field
                                TextFormField(
                                  controller: prenomController,
                                  decoration: buildInputDeco(
                                    labelText: 'Prénom',
                                    prefixIcon: Icons.person_outline_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                        return 'Veuillez saisir votre prénom';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Nom Field
                                TextFormField(
                                  controller: nomController,
                                  decoration: buildInputDeco(
                                    labelText: 'Nom',
                                    prefixIcon: Icons.person_outline_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Veuillez saisir votre nom';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Email Field
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: buildInputDeco(
                                    labelText: 'Adresse Email',
                                    prefixIcon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Veuillez saisir votre email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Veuillez saisir un email valide';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Téléphone Field
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: buildInputDeco(
                                    labelText: 'Téléphone',
                                    prefixIcon: Icons.phone_outlined,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Nouveau mot de passe (optionnel)
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  decoration: buildInputDeco(
                                    labelText: 'Nouveau mot de passe (optionnel)',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty && value.length < 8) {
                                      return 'Le mot de passe doit contenir au moins 8 caractères';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Save Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF59E0B),
                                  Color(0xFFD97706),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD97706).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        FocusScope.of(context).unfocus();
                                        setModalState(() {
                                          isSaving = true;
                                        });
                                        
                                        try {
                                          final data = await AuthService().updateProfile(
                                            nom: nomController.text.trim(),
                                            prenom: prenomController.text.trim(),
                                            email: emailController.text.trim(),
                                            telephone: phoneController.text.trim(),
                                            password: passwordController.text.isNotEmpty ? passwordController.text : null,
                                          );
                                          
                                          if (data != null && mounted) {
                                            setState(() {
                                              _userNom = data['nom'] ?? '';
                                              _userPrenom = data['prenom'] ?? '';
                                              _userName = '$_userPrenom $_userNom'.trim();
                                              _userEmail = data['email'] ?? '';
                                              _userPhone = data['telephone'] ?? '';
                                            });
                                            
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Row(
                                                  children: [
                                                    Icon(Icons.check_circle_outline, color: Colors.white),
                                                    SizedBox(width: 8),
                                                    Text('Profil mis à jour avec succès !'),
                                                  ],
                                                ),
                                                backgroundColor: AppColors.success,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          String errorMsg = e.toString();
                                          if (errorMsg.contains('déjà utilisée') || errorMsg.contains('409') || errorMsg.contains('500') || errorMsg.contains('400')) {
                                            errorMsg = "Cette adresse email est déjà utilisée par un autre compte.";
                                          } else {
                                            errorMsg = "Une erreur est survenue lors de la mise à jour.";
                                          }
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text(errorMsg)),
                                                ],
                                              ),
                                              backgroundColor: AppColors.error,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          );
                                        } finally {
                                          setModalState(() {
                                            isSaving = false;
                                          });
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Enregistrer les modifications',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
