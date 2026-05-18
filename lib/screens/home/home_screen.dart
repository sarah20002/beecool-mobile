import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/bee_logo.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import 'qr_scanner_screen.dart';
import '../cart/cart_screen.dart';
import '../reservation/reservation_step1.dart';
import '../profile/profile_screen.dart';
import '../menu/dish_detail_screen.dart';
import '../../core/utils/notification_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  
  List<dynamic> _etablissements = [];
  List<dynamic> _plats = [];
  bool _isLoadingEtablissements = true;
  bool _isLoadingPlats = false;
  String? _selectedEtablissementId;
  String _userPrenom = 'Client';
  int _userPoints = 0;
  String _userImage = '';
  bool _isRealClient = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchEtablissements();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (mounted) {
      setState(() {
        _userPrenom = prefs.getString('user_prenom') ?? 'Client';
        _userPoints = prefs.getInt('user_points') ?? 0;
        _userImage = prefs.getString('user_image') ?? '';
        _isRealClient = email != null && email.isNotEmpty;
      });
    }
  }

  Future<void> _fetchEtablissements() async {
    try {
      final response = await _dio.get(ApiConfig.etablissements);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _etablissements = response.data;
          _isLoadingEtablissements = false;
          if (_etablissements.isNotEmpty) {
            _selectedEtablissementId = _etablissements[0]['id'];
            _fetchPlats(_selectedEtablissementId!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEtablissements = false);
      }
    }
  }

  Future<void> _fetchPlats(String etablissementId) async {
    setState(() => _isLoadingPlats = true);
    try {
      final response = await _dio.get(ApiConfig.platsParEtablissement(etablissementId));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _plats = response.data;
          _isLoadingPlats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plats = [];
          _isLoadingPlats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFA),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // MAIN SCROLLABLE CONTENT
          SafeArea(
            child: Builder(
              builder: (context) => Column(
                children: [
                  _buildFloatingHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildGreeting(),
                          const SizedBox(height: 20),
                          _buildBanners(context),
                          const SizedBox(height: 30),
                           _buildWaterBox(_buildBranchesSection()),
                           const SizedBox(height: 30),
                           _buildWaterBox(
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 _buildPopularDishesHeader(),
                                 const SizedBox(height: 15),
                                 _buildPopularDishesGrid(context),
                               ],
                             ),
                           ),
                          const SizedBox(height: 140), // Space for fixed buttons
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // QR SCANNER BUTTON - Fixed and very close to Nav
          Positioned(
            bottom: 20, // Adjusted to bring closer to bottom navigation
            right: 20,
            child: FadeInRight(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, Color(0xFFD48400)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFloatingHeader(BuildContext context) {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Bee Illustration
            const BeeIllustration(height: 35),
            
            // Center: Brand Text
            const BeeTextLogo(fontSize: 22),
            
            // Right: User Profile with Badge
            GestureDetector(
              onTap: () {
                if (_isRealClient) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                } else {
                  NotificationHelper.showWarning(
                    context, 
                    title: "Accès limité", 
                    message: "Veuillez créer un compte pour accéder à votre profil."
                  );
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _userImage.isNotEmpty
                          ? NetworkImage(_userImage)
                          : const NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80') as ImageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000410),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '$_userPoints',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bienvenue', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
              children: [
                TextSpan(text: 'Bonjour, $_userPrenom '),
                const TextSpan(text: '👋', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanners(BuildContext context) {
    if (_isLoadingEtablissements) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (_etablissements.isEmpty) {
      return const SizedBox();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _etablissements.map((etab) {
          final nom = etab['nom'] ?? 'Établissement';
          final adresse = etab['adresse'] ?? '';
          final imageUrl = (etab['image'] != null && etab['image'].toString().isNotEmpty) 
              ? etab['image'] 
              : 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80';
          
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: _buildBannerCard(
              context,
              title: nom,
              tag: adresse.toUpperCase(),
              imageUrl: imageUrl,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, {required String title, required String tag, required String imageUrl}) {
    return Container(
      width: 280,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_isRealClient) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ReservationStep1()));
                } else {
                  NotificationHelper.showWarning(
                    context, 
                    title: "Accès limité", 
                    message: "Veuillez créer un compte pour pouvoir réserver."
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
              child: const Text('RÉSERVER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchesSection() {
    if (_isLoadingEtablissements || _etablissements.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nos Branches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              TextButton(onPressed: () {}, child: const Text('VOIR TOUT', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _etablissements.map((etab) {
                final isSelected = _selectedEtablissementId == etab['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEtablissementId = etab['id']);
                    _fetchPlats(etab['id']);
                  },
                  child: _buildBranchChip(etab['nom'] ?? 'Inconnu', isSelected: isSelected),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchChip(String name, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.secondary : Colors.white,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 12, color: isSelected ? AppColors.secondary : Colors.grey),
          const SizedBox(width: 6),
          Text(
            name, 
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey.shade600, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
              fontSize: 12
            )
          ),
        ],
      ),
    );
  }

  Widget _buildPopularDishesHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text('Plats Populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _buildPopularDishesGrid(BuildContext context) {
    if (_isLoadingPlats) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (_plats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("Aucun plat disponible pour cet établissement", style: TextStyle(color: Colors.grey))),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.72,
        ),
        itemCount: _plats.length,
        itemBuilder: (context, index) {
          final plat = _plats[index];
          final priceStr = plat['prix'] != null ? '${plat['prix']} DT' : '0.0 DT';
          final imageUrl = (plat['image'] != null && plat['image'].toString().isNotEmpty)
              ? plat['image']
              : 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80';
              
          return _buildDishCard(context, plat);
        },
      ),
    );
  }

     // Helper to create water droplet styled container for sections
     Widget _buildWaterBox(Widget child) {
       return ClipRRect(
         borderRadius: BorderRadius.circular(20),
         child: BackdropFilter(
           filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
           child: Container(
             padding: const EdgeInsets.symmetric(vertical: 8),
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
             ),
             child: child,
           ),
         ),
       );
     }

  Widget _buildDishCard(BuildContext context, Map<String, dynamic> plat) {
    final name = plat['nom'] ?? 'Plat';
    final price = plat['prix'] != null ? '${plat['prix']} DT' : '0.0 DT';
    final imageUrl = (plat['image'] != null && plat['image'].toString().isNotEmpty)
        ? plat['image']
        : 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DishDetailScreen(dish: plat)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: Colors.grey.shade100)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8, 
                      right: 8, 
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(price, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BeeIllustration(height: 50),
                  SizedBox(height: 15),
                  BeeTextLogo(fontSize: 22, color: Colors.white),
                ],
              ),
            ),
            _buildDrawerItem(icon: Icons.qr_code_scanner, title: 'Scanner un QR Code', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
            }),
            _buildDrawerItem(icon: Icons.calendar_today, title: 'Mes Réservations', onTap: () {
              Navigator.pop(context);
              if (_isRealClient) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReservationStep1()));
              } else {
                NotificationHelper.showWarning(
                  context, 
                  title: "Accès limité", 
                  message: "Veuillez créer un compte pour pouvoir réserver."
                );
              }
            }),
            _buildDrawerItem(icon: Icons.restaurant_menu, title: 'Carte & Menu', onTap: () {}),
            const Spacer(),
            _buildDrawerItem(icon: Icons.logout, title: 'Déconnexion', onTap: () {}, isLast: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, bool isLast = false}) {
    return ListTile(
      leading: Icon(icon, color: isLast ? Colors.redAccent : AppColors.secondary),
      title: Text(title, style: TextStyle(color: isLast ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
