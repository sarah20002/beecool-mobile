import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../core/services/favorites_service.dart';
import '../../core/utils/notification_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedCategoryFilter = 'Tout';
  List<dynamic> _allFavorites = [];
  List<dynamic> _dbCategories = [];
  List<dynamic> _etablissements = [];
  String? _selectedEtablissementId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final list = await FavoritesService().getFavorites();
      
      // Récupérer la liste des établissements
      List<dynamic> etablissements = [];
      String? activeEtabId;
      try {
        final dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'X-Platform': 'mobile',
          },
        ));
        final etabResp = await dio.get('/etablissements');
        if (etabResp.statusCode == 200) {
          etablissements = etabResp.data as List;
        }

        final prefs = await SharedPreferences.getInstance();
        activeEtabId = prefs.getString('etablissement_id');

        if (activeEtabId == null || activeEtabId.isEmpty) {
          if (etablissements.isNotEmpty) {
            activeEtabId = etablissements[0]['id']?.toString();
          }
        }
      } catch (e) {
        debugPrint('Error loading establishments: $e');
      }

      if (mounted) {
        setState(() {
          _allFavorites = list;
          _etablissements = etablissements;
          _selectedEtablissementId = activeEtabId;
        });
      }

      if (activeEtabId != null && activeEtabId.isNotEmpty) {
        await _loadCategoriesForEtablissement(activeEtabId);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategoriesForEtablissement(String etabId) async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Platform': 'mobile',
        },
      ));
      final catResp = await dio.get(ApiConfig.categoriesParEtablissement(etabId));
      if (mounted) {
        setState(() {
          _dbCategories = catResp.data as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dbCategories = [];
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryOfFavorite(dynamic fav) {
    final String? catName = fav['categorieNom'];
    if (catName != null && catName.isNotEmpty) {
      return catName[0].toUpperCase() + catName.substring(1).toLowerCase();
    }
    return 'Plats';
  }

  List<dynamic> get _favoritesOfSelectedEtablissement {
    if (_selectedEtablissementId == null) return [];
    return _allFavorites.where((fav) {
      final String? etabIdOfFav = fav['etablissementId']?.toString();
      if (etabIdOfFav == null || etabIdOfFav.isEmpty) {
        return true; // Fallback pour les anciens favoris
      }
      return etabIdOfFav == _selectedEtablissementId;
    }).toList();
  }

  List<String> get _categories {
    final Set<String> cats = {'Tout'};
    if (_dbCategories.isNotEmpty) {
      for (var cat in _dbCategories) {
        final String? nom = cat['nom'];
        if (nom != null && nom.isNotEmpty) {
          cats.add(nom[0].toUpperCase() + nom.substring(1).toLowerCase());
        }
      }
    } else {
      for (var fav in _favoritesOfSelectedEtablissement) {
        cats.add(_getCategoryOfFavorite(fav));
      }
    }
    return cats.toList();
  }

  List<dynamic> get _filteredFavorites {
    final list = _favoritesOfSelectedEtablissement;
    if (_selectedCategoryFilter == 'Tout') {
      return list;
    }
    return list.where((fav) {
      return _getCategoryOfFavorite(fav).toLowerCase() == _selectedCategoryFilter.toLowerCase();
    }).toList();
  }

  int _countCategory(String category) {
    final list = _favoritesOfSelectedEtablissement;
    if (category == 'Tout') {
      return list.length;
    }
    return list.where((fav) {
      return _getCategoryOfFavorite(fav).toLowerCase() == category.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(statusBarHeight),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  child: _buildFilterTabs(),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: _isLoading
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.secondary),
                          ),
                        ),
                      )
                    : _filteredFavorites.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState())
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.74,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final fav = _filteredFavorites[index];
                                return _buildFavoriteCard(fav, index);
                              },
                              childCount: _filteredFavorites.length,
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    final count = _favoritesOfSelectedEtablissement.length;
    return Container(
      height: 290, // Increased to perfectly fit etablissement selector!
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?auto=format&fit=crop&q=80&w=400',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 40,
            right: 5,
            child: Icon(
              Icons.favorite_rounded,
              color: const Color(0xFFFC9910).withOpacity(0.08),
              size: 130,
            ),
          ),
          
          Padding(
            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    
                    const Text(
                      'Mes favoris',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                const Text(
                  'MES COUPS DE CŒUR',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      count <= 1 ? 'plat sauvegardé' : 'plats sauvegardés',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                _buildEtablissementSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtablissementSelector() {
    if (_etablissements.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _etablissements.length,
        itemBuilder: (context, index) {
          final etab = _etablissements[index];
          final String etabId = etab['id']?.toString() ?? '';
          final String etabNom = etab['nom'] ?? 'Établissement';
          final bool isSelected = _selectedEtablissementId == etabId;

          return GestureDetector(
            onTap: () {
              if (_selectedEtablissementId != etabId) {
                setState(() {
                  _selectedEtablissementId = etabId;
                  _selectedCategoryFilter = 'Tout';
                });
                _loadCategoriesForEtablissement(etabId);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFC9910) : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFC9910) : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                etabNom,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    final categories = _categories;
    return SizedBox(
      height: 38,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: categories.map((cat) {
            return _buildTabItem(cat, cat, _countCategory(cat));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabItem(String category, String label, int count) {
    bool isSelected = _selectedCategoryFilter == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF132B49) : const Color(0xFFE2E8F0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF132B49) : Colors.transparent,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            // Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFC9910) : const Color(0xFF64748B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(dynamic fav, int index) {
    final bool isSpecialBg = false;
    
    // Fallback image in case backend doesn't provide one
    final String imageUrl = (fav['image'] != null && fav['image'].toString().isNotEmpty)
        ? fav['image'].toString()
        : 'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?auto=format&fit=crop&q=80&w=250';

    final String nom = fav['nom'] ?? 'Plat';
    final String category = _getCategoryOfFavorite(fav);
    
    // Format price elegantly
    final String priceStr = fav['prix'] != null ? fav['prix'].toString() : '0';

    // Aesthetic ratings/counts derived cleanly to feel extremely alive and editorial
    final String rating = index % 2 == 0 ? '4.9' : '4.8';
    final String orderCount = index == 0 
        ? 'Nouveau'
        : index == 1
            ? 'Commandé 5×'
            : 'Commandé 3×';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Image Container with rating and category badges
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Special Orange Background (like card 1 in screenshot)
                  if (isSpecialBg) ...[
                    Container(
                      color: const Color(0xFFFD8A14), // vibrant orange backdrop
                    ),
                  ],
                  
                  // Plate image centered
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(isSpecialBg ? 12.0 : 0.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isSpecialBg ? 100 : 0),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Rating Badge (Top Left / Bottom Left depending on design, matching screenshot on bottom-left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category Capsule (Bottom Right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Color(0xFFFD8A14),
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Heart button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final String platId = fav['id'].toString();
                        final bool success = await FavoritesService().removeFavorite(platId);
                        
                        if (success && mounted) {
                          setState(() {
                            _allFavorites.removeWhere((f) => f['id'].toString() == platId);
                          });
                          NotificationHelper.showSuccess(
                            context,
                            title: "Retiré",
                            message: "$nom a été retiré de vos favoris.",
                          );
                        } else if (mounted) {
                          NotificationHelper.showError(
                            context,
                            title: "Erreur",
                            message: "Impossible de retirer le plat de vos favoris.",
                            onRetry: () {},
                          );
                        }
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dish Title
                Text(
                  nom,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),

                // Subtitle / Order Count
                Text(
                  orderCount,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),

                // Bottom row: Price + Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      textBaseline: TextBaseline.alphabetic,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      children: [
                        Text(
                          priceStr,
                          style: const TextStyle(
                            color: Color(0xFFFD8A14),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'DT',
                          style: TextStyle(
                            color: Color(0xFFFD8A14),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        final String platId = fav['id'].toString();
                        final bool success = await FavoritesService().removeFavorite(platId);
                        
                        if (success && mounted) {
                          setState(() {
                            _allFavorites.removeWhere((f) => f['id'].toString() == platId);
                          });
                          NotificationHelper.showSuccess(
                            context,
                            title: "Retiré",
                            message: "$nom a été retiré de vos favoris.",
                          );
                        } else if (mounted) {
                          NotificationHelper.showError(
                            context,
                            title: "Erreur",
                            message: "Impossible de retirer le plat de vos favoris.",
                            onRetry: () {},
                          );
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.shade100, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade600,
                          size: 15,
                        ),
                      ),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun favori sauvegardé',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 54.0; // 38 height of tabs + 16 vertical padding
  @override
  double get maxExtent => 54.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background, // same as page background so the grid/list scrolls cleanly behind it
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return true;
  }
}
