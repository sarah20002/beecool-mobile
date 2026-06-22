import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';

import 'dart:ui';

import '../../core/theme/app_colors.dart';

import '../../widgets/custom_bottom_nav.dart';



import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/notification_helper.dart';
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
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'X-Platform': 'mobile',
    },
  ));
  
  List<dynamic> _categories = [];
  List<dynamic> _plats = [];
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;
  List<String> _favoritePlatIds = [];
  bool _isRealClient = false;

  List<dynamic> _recommendedDishes = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    CartService().setEtablissementId(widget.etablissementId);
    if (widget.sessionToken != null) {
      CartService().setSessionToken(widget.sessionToken!);
    }
    _checkClientAndLoadFavorites();
    _fetchMenu();
  }

  Future<void> _checkClientAndLoadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('user_id') ?? '';
    if (clientId.isNotEmpty) {
      setState(() {
        _isRealClient = true;
      });
      _loadFavorites();
    }
  }

  Future<void> _loadRecommendedDishes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDishId = prefs.getString('last_consulted_dish_id');
      debugPrint('[Menu Recommandations] Dernier plat consulte ID : $lastDishId');
      if (lastDishId == null) {
        if (mounted) {
          setState(() {
            _recommendedDishes = [];
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoadingRecommendations = true;
        });
      }

      final token = await AuthService().getToken();
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Platform': 'mobile',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ));

      final url = ApiConfig.aiRecommend(lastDishId, etablissementId: widget.etablissementId);
      debugPrint('[Menu Recommandations] Appel de l\'URL : ${ApiConfig.baseUrl}$url');
      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('[Menu Recommandations] Reponse recue : ${response.data}');
        List<dynamic> rawList = [];
        if (response.data is Map) {
          final dataMap = response.data as Map;
          final listData = dataMap['recommandations'] ?? dataMap['recommendations'] ?? dataMap['plats'] ?? dataMap['items'] ?? dataMap['dishes'] ?? dataMap['data'];
          if (listData is List) {
            rawList = listData;
          } else {
            for (var val in dataMap.values) {
              if (val is List) {
                rawList = val;
                break;
              }
            }
          }
        } else if (response.data is List) {
          rawList = response.data;
        }

        List<dynamic> resolvedDishes = [];
        if (rawList.isNotEmpty) {
          if (rawList.first is String || rawList.first is num || rawList.first is int) {
            final ids = rawList.map((id) => id.toString()).toSet();
            resolvedDishes = _plats.where((p) => ids.contains(p['id'].toString())).toList();
          } else if (rawList.first is Map) {
            final ids = rawList.map((item) {
              if (item is Map) {
                return (item['plat_id'] ?? item['id'])?.toString();
              }
              return null;
            }).where((id) => id != null).cast<String>().toSet();

            resolvedDishes = _plats.where((p) => ids.contains(p['id'].toString())).toList();
          }
        }

        debugPrint('[Menu Recommandations] Plats resolus : ${resolvedDishes.map((p) => p['nom']).toList()}');

        if (mounted) {
          setState(() {
            _recommendedDishes = resolvedDishes;
            _isLoadingRecommendations = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingRecommendations = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[Menu Recommandations] Exception : $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final list = await FavoritesService().getFavorites();
      if (mounted) {
        setState(() {
          _favoritePlatIds = list.map((fav) => fav['id'].toString()).toList();
        });
      }
    } catch (e) {
      // ignore
    }
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
        _loadRecommendedDishes();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredPlats {
    if (_categories.isEmpty || _selectedCategoryIndex == 0) return _plats;
    final catId = _categories[_selectedCategoryIndex]['id'];
    return _plats.where((p) => p['categorieId'] != null && p['categorieId'] == catId).toList();
  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: SingleChildScrollView(

        child: Column(

          children: [

            _buildBanner(),

            const SizedBox(height: 5),

            _buildPopularDishes(),

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
          height: 290,
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
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          child: GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Center(child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 20,
          child: FadeInLeft(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                children: [
                  TextSpan(text: 'Notre ', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'Menu', style: TextStyle(color: Color(0xFFF8A11C), fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: Container(
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildPopularDishes() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final hasRecommendations = _recommendedDishes.isNotEmpty;
    final List<dynamic> dishesToShow;
    final String sectionTitle;

    if (hasRecommendations) {
      dishesToShow = _recommendedDishes;
      sectionTitle = 'Plats Recommandés';
    } else {
      final popularPlats = _plats.where((p) {
        return p['populaire'] == true || p['isPopular'] == true || p['popular'] == true;
      }).toList();
      dishesToShow = popularPlats.isNotEmpty ? popularPlats : _plats.take(5).toList();
      sectionTitle = 'Plats Populaires';
    }

    if (dishesToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: dishesToShow.length,
            itemBuilder: (context, index) {
              final item = dishesToShow[index];
              final imageUrl = (item['image'] != null && item['image'].toString().isNotEmpty)
                  ? item['image']
                  : 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=400&q=80';
              final priceStr = item['prixPromotion'] != null 
                  ? '${item['prixPromotion']} DT' 
                  : (item['prix'] != null ? '${item['prix']} DT' : '0 DT');

              return FadeInRight(
                delay: Duration(milliseconds: 100 * index),
                child: GestureDetector(
                  onTap: () {
                    final related = _plats.where((p) => p['categorieId'] == item['categorieId'] && p['id'] != item['id']).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DishDetailScreen(
                          dish: item,
                          relatedDishes: related,
                          allDishes: _plats,
                        ),
                      ),
                    ).then((_) {
                      _loadRecommendedDishes();
                    });
                  },
                  child: Container(
                    width: 125,
                    margin: const EdgeInsets.only(right: 15, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.network(
                            imageUrl,
                            height: 85,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 85,
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 25)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['nom'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                priceStr,
                                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
        final promoPriceStr = item['prixPromotion'] != null ? '${item['prixPromotion']} DT' : null;
        
        String badgeText = '';
        if (promoPriceStr != null && item['valeurPromotion'] != null) {
          if (item['typePromotion'] == 'POURCENTAGE') {
            badgeText = '-${item['valeurPromotion']}%';
          } else {
            badgeText = '-${item['valeurPromotion']} DT';
          }
        }
        final imageUrl = (item['image'] != null && item['image'].toString().isNotEmpty) 
            ? item['image'] 
            : 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=400&q=80';

        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: GestureDetector(
            onTap: () {
              final related = _plats.where((p) => p['categorieId'] == item['categorieId'] && p['id'] != item['id']).toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DishDetailScreen(
                    dish: item,
                    relatedDishes: related,
                    allDishes: _plats,
                  ),
                ),
              ).then((_) {
                _loadRecommendedDishes();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
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
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 90, height: 90, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 30)))),
                      ),
                      if (badgeText.isNotEmpty)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () async {
                            if (!_isRealClient) {
                              NotificationHelper.showWarning(
                                context, 
                                title: "Accès limité", 
                                message: "Veuillez créer un compte pour ajouter des favoris."
                              );
                              return;
                            }
                            
                            final platId = item['id'].toString();
                            final isFav = _favoritePlatIds.contains(platId);
                            final success = isFav 
                                ? await FavoritesService().removeFavorite(platId)
                                : await FavoritesService().addFavorite(platId);
                            
                            if (success && mounted) {
                              setState(() {
                                if (isFav) {
                                  _favoritePlatIds.remove(platId);
                                } else {
                                  _favoritePlatIds.add(platId);
                                }
                              });
                              
                              NotificationHelper.showSuccess(
                                context,
                                title: isFav ? "Retiré des favoris" : "Ajouté aux favoris",
                                message: isFav 
                                    ? "${item['nom']} a été retiré de vos favoris."
                                    : "${item['nom']} a été ajouté à vos favoris."
                              );
                            } else if (mounted) {
                              NotificationHelper.showError(
                                context,
                                title: "Erreur",
                                message: "Une erreur est survenue lors de la modification des favoris.",
                                onRetry: () {},
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            ),
                            child: Icon(
                              _favoritePlatIds.contains(item['id'].toString())
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: _favoritePlatIds.contains(item['id'].toString())
                                  ? Colors.amber
                                  : Colors.grey.shade600,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nom'] ?? '', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 36, // Hauteur fixe pour afficher environ 2 lignes
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              item['description'] ?? '', 
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (promoPriceStr != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(priceStr, style: TextStyle(color: Colors.grey.shade400, decoration: TextDecoration.lineThrough, fontSize: 12)),
                              ),
                            Text(promoPriceStr ?? priceStr, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 15)),
                          ]
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      CartService().addItem(CartItem(
                        id: item['id'].toString(),
                        name: item['nom'] ?? 'Plat',
                        price: double.tryParse(item['prix']?.toString() ?? '') ?? 0.0,
                        imageUrl: imageUrl,
                        quantity: 1,
                      ));
                      NotificationHelper.showSuccess(
                        context,
                        title: "Ajouté au panier",
                        message: "${item['nom']} a été ajouté à votre panier."
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
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