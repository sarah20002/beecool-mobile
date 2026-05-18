import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';

import 'dart:ui';

import '../../core/theme/app_colors.dart';

import '../../widgets/custom_bottom_nav.dart';



import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/cart_service.dart';
import 'dish_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final String etablissementId;
  final String? sessionToken;

  const MenuScreen({
    super.key, 
    required this.etablissementId, 
    this.sessionToken,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  
  List<dynamic> _categories = [];
  List<dynamic> _plats = [];
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    CartService().setEtablissementId(widget.etablissementId);
    if (widget.sessionToken != null) {
      CartService().setSessionToken(widget.sessionToken!);
    }
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      final catResponse = await _dio.get(ApiConfig.categoriesParEtablissement(widget.etablissementId));
      final platsResponse = await _dio.get(ApiConfig.platsParEtablissement(widget.etablissementId));
      
      if (mounted) {
        setState(() {
          _categories = catResponse.data ?? [];
          if (_categories.isEmpty || _categories.first['nom'] != 'Tout') {
            _categories.insert(0, {'id': 'ALL', 'nom': 'Tout'});
          }
          _plats = platsResponse.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredPlats {
    if (_categories.isEmpty || _selectedCategoryIndex == 0) return _plats;
    final catId = _categories[_selectedCategoryIndex]['id'];
    // Vérifier selon la structure de retour backend (categorie.id ou categorieId)
    return _plats.where((p) => p['categorie'] != null && p['categorie']['id'] == catId).toList();
  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: SingleChildScrollView(

        child: Column(

          children: [

            _buildBanner(),

            const SizedBox(height: 20),

            _buildCategories(),

            const SizedBox(height: 10),

            _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(50.0), child: CircularProgressIndicator()))
              : _buildMenuList(),

            const SizedBox(height: 100), // Space for bottom nav

          ],

        ),

      ),

      bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),

      floatingActionButton: CustomBottomNav.buildCartFAB(context),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );

  }



  Widget _buildBanner() {

    return Stack(

      children: [

        Container(

          height: 250,

          width: double.infinity,

          decoration: const BoxDecoration(

            image: DecorationImage(

              image: NetworkImage('https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80'),

              fit: BoxFit.cover,

            ),

          ),

          child: Container(

            decoration: BoxDecoration(

              gradient: LinearGradient(

                begin: Alignment.topCenter,

                end: Alignment.bottomCenter,

                colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],

              ),

            ),

          ),

        ),

        Positioned(

          bottom: 30,

          left: 20,

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              FadeInLeft(

                child: const Text(

                  'Notre Menu',

                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Serif'),

                ),

              ),

              const SizedBox(height: 10),

              FadeInUp(

                child: ClipRRect(

                  borderRadius: BorderRadius.circular(20),

                  child: BackdropFilter(

                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

                    child: Container(

                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),

                      decoration: BoxDecoration(

                        color: Colors.white.withOpacity(0.15),

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),

                      ),

                      child: const Row(

                        children: [

                          Icon(Icons.qr_code_scanner, color: AppColors.secondary, size: 16),

                          SizedBox(width: 8),

                          Text(

                            'Scannez le code sur table pour commander',

                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

              ),

            ],

          ),

        ),

      ],

    );

  }



  Widget _buildCategories() {
    if (_isLoading || _categories.isEmpty) return const SizedBox(height: 45);

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary.withOpacity(0.7) : const Color(0xFFF3F4F6).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _categories[index]['nom'] ?? 'Catégorie',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildMenuList() {
    final items = _filteredPlats;
    if (items.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(50), child: Text("Aucun plat disponible")));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final priceStr = item['prix'] != null ? '${item['prix']} DT' : '0 DT';
        final imageUrl = (item['image'] != null && item['image'].toString().isNotEmpty) 
            ? item['image'] 
            : 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=400&q=80';

        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DishDetailScreen(dish: item),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1.2),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(item['description'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        Text(priceStr, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}