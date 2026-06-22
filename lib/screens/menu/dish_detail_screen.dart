import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/cart_service.dart';
import '../cart/cart_screen.dart';
import '../home/qr_scanner_screen.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/favorites_service.dart';
import '../../core/utils/notification_helper.dart';

class DishDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dish;
  final bool isEditing;
  final int? cartItemIndex;
  final String? initialNotes;
  final int? initialQuantity;
  final List<dynamic>? relatedDishes;
  final List<dynamic>? allDishes;

  const DishDetailScreen({
    super.key,
    required this.dish,
    this.isEditing = false,
    this.cartItemIndex,
    this.initialNotes,
    this.initialQuantity,
    this.relatedDishes,
    this.allDishes,
  });

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _quantity = 1;
  late final TextEditingController _notesController;
  bool _isFavorite = false;
  bool _isRealClient = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity ?? 1;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _saveLastConsultedDish();
    _checkClientAndLoadFavorites();
  }

  Future<void> _checkClientAndLoadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? '';
      _isRealClient = userEmail.isNotEmpty && !userEmail.startsWith('GUEST');
      if (_isRealClient) {
        final list = await FavoritesService().getFavorites();
        final dishId = widget.dish['id']?.toString();
        if (dishId != null && list.any((fav) => fav['id'].toString() == dishId)) {
          if (mounted) {
            setState(() {
              _isFavorite = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[DishDetail] Erreur chargement favoris: $e');
    }
  }

  Future<void> _saveLastConsultedDish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dishId = widget.dish['id']?.toString();
      if (dishId != null) {
        await prefs.setString('last_consulted_dish_id', dishId);
        debugPrint('[DishDetail] Enregistrement du dernier plat consulte : $dishId');
      }
    } catch (e) {
      debugPrint('[DishDetail] Erreur enregistrement dernier plat consulte : $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (!_isRealClient) {
      NotificationHelper.showWarning(
        context, 
        title: "Accès limité", 
        message: "Veuillez créer un compte pour ajouter des favoris."
      );
      return;
    }

    final dishId = widget.dish['id']?.toString();
    if (dishId == null) return;

    try {
      final success = _isFavorite 
          ? await FavoritesService().removeFavorite(dishId)
          : await FavoritesService().addFavorite(dishId);
      
      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        NotificationHelper.showSuccess(
          context,
          title: _isFavorite ? "Ajouté aux favoris" : "Retiré des favoris",
          message: _isFavorite 
              ? "${widget.dish['nom'] ?? 'Le plat'} a été ajouté à vos favoris."
              : "${widget.dish['nom'] ?? 'Le plat'} a été retiré de vos favoris."
        );
      } else if (mounted) {
        NotificationHelper.showError(
          context,
          title: "Erreur",
          message: "Une erreur est survenue lors de la modification des favoris.",
          onRetry: () {}
        );
      }
    } catch (e) {
      debugPrint('[DishDetail] Erreur toggle favoris: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addToCart() {
    FocusScope.of(context).unfocus();
    
    if (widget.isEditing && widget.cartItemIndex != null) {
      CartService().updateItem(
        widget.cartItemIndex!,
        quantity: _quantity,
        notes: _notesController.text.trim(),
      );
      Navigator.pop(context);
      return;
    }

    final name = widget.dish['nom'] ?? 'Plat';
    final price = widget.dish['prixPromotion'] != null 
        ? (widget.dish['prixPromotion'] as num?)?.toDouble() ?? 0.0 
        : (widget.dish['prix'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = (widget.dish['image'] != null && widget.dish['image'].toString().isNotEmpty)
        ? widget.dish['image']
        : 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=400&q=80';

    final cartItem = CartItem(
      id: widget.dish['id'].toString(),
      name: name,
      price: price,
      imageUrl: imageUrl,
      quantity: _quantity,
      notes: _notesController.text.trim(),
    );

    CartService().addItem(cartItem);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.dish['nom'] ?? 'Plat';
    final priceStr = widget.dish['prix'] != null ? '${widget.dish['prix']} DT' : '0 DT';
    final promoPriceStr = widget.dish['prixPromotion'] != null ? '${widget.dish['prixPromotion']} DT' : null;
    
    String badgeText = '';
    if (promoPriceStr != null && widget.dish['valeurPromotion'] != null) {
      if (widget.dish['typePromotion'] == 'POURCENTAGE') {
        badgeText = '-${widget.dish['valeurPromotion']}%';
      } else {
        badgeText = '-${widget.dish['valeurPromotion']} DT';
      }
    }
    final description = widget.dish['description'] ?? 'Aucune description disponible pour ce plat raffiné.';
    final imageUrl = (widget.dish['image'] != null && widget.dish['image'].toString().isNotEmpty)
        ? widget.dish['image']
        : 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=400&q=80';
    
    final List<dynamic> ingredients = widget.dish['ingredients'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Image (Fixed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320, // Reduced from 420
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    imageUrl, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40)),
                      );
                    },
                  ),
                ),

                // Gradual dark gradient at bottom of image for text readability
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                      ),
                    ),
                  ),
                ),
                // Prep time badge on image
                Positioned(
                  bottom: 40, // Above the white sheet overlap
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFC9910)),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.dish['tempsPrep'] ?? 15} min',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
                // Promo badge on image
                if (badgeText.isNotEmpty)
                  Positioned(
                    bottom: 40,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            badgeText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Scrollable Content overlay
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 290), // Reduced from 380 to match new image height
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC), // Off-white app background
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Title & Price
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFC9910), Color(0xFFD48400)]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFFFC9910).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (promoPriceStr != null)
                                    Text(
                                      priceStr,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    promoPriceStr ?? priceStr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Ratings
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFC9910), size: 16),
                                  const SizedBox(width: 4),
                                  const Text('4.9', style: TextStyle(color: Color(0xFFFC9910), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '(120+ Avis clients)',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // The Experience (Description)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20), // Matched with Special Note container
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))], // Matched with Special Note shadow
                              ),
                              child: Text(
                                description,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.6, letterSpacing: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Key Ingredients
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ingrédients Clés',
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 15),
                            if (ingredients.isNotEmpty)
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: ingredients.map((ing) {
                                  String ingName = 'Ingrédient';
                                  if (ing is Map) {
                                    if (ing['ingredient'] != null && ing['ingredient'] is Map) {
                                      ingName = ing['ingredient']['nom']?.toString() ?? 'Ingrédient';
                                    } else if (ing['nom'] != null) {
                                      ingName = ing['nom'].toString();
                                    }
                                  } else {
                                    ingName = ing.toString();
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFC9910).withOpacity(0.1), // Orange subtle background
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFC9910).withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFFFC9910), size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          ingName,
                                          style: const TextStyle(color: Color(0xFFD48400), fontSize: 13, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                'Aucun ingrédient spécifié pour ce plat.',
                                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Special Note for Chef
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Note spéciale pour le chef',
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: TextField(
                                controller: _notesController,
                                decoration: InputDecoration(
                                  hintText: 'ex. Bien cuit, sans oignons...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.secondary),
                                ),
                                maxLines: 4,
                                minLines: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Same Category / Related Dishes
                      if (widget.relatedDishes != null && widget.relatedDishes!.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            'Dans la même catégorie',
                            style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.relatedDishes!.length,
                            itemBuilder: (context, index) {
                              final relatedDish = widget.relatedDishes![index];
                              final relatedImg = (relatedDish['image'] != null && relatedDish['image'].toString().isNotEmpty)
                                  ? relatedDish['image']
                                  : 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=400&q=80';
                              final relatedPrice = relatedDish['prix'] != null ? '${relatedDish['prix']} DT' : '0 DT';
                              
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DishDetailScreen(
                                        dish: relatedDish,
                                        relatedDishes: widget.relatedDishes!
                                            .where((d) => d['id'] != relatedDish['id'])
                                            .toList()
                                            ..add(widget.dish),
                                        allDishes: widget.allDishes,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 15, bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: Image.network(relatedImg, height: 100, width: 140, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 100, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)))),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              relatedDish['nom'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              relatedPrice,
                                              style: const TextStyle(color: Color(0xFFFC9910), fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 130), // Padding for bottom bar
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Navigation Icons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circularIcon(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  _circularIcon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    _toggleFavorite,
                    color: _isFavorite ? Colors.amber : Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // Fixed Bottom Bar
          if (CartService().sessionToken != null) 
            _buildBottomBar()
          else
            _buildOrderRequiredMessage(),
        ],
      ),
    );
  }

  // _buildStatCard removed

  Widget _buildOrderRequiredMessage() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consultation uniquement',
                    style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Scannez le QR Code de votre table pour commander.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'SCANNER',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 20,
              spreadRadius: 20,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Row(
          children: [
            // Quantity Selector
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withOpacity(0.6), // Light blueish grey
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18, color: Color(0xFF0F172A)), 
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null)
                  ),
                  SizedBox(
                    width: 16,
                    child: Text(
                      '$_quantity', 
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFF0F172A)), 
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () => setState(() => _quantity++)
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Add to Cart Button
            Expanded(
              child: GestureDetector(
                onTap: _addToCart,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC9910), // Solid Orange
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFC9910).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.isEditing ? 'Confirmer' : 'Ajouter au panier',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        widget.isEditing ? Icons.check_circle_outline_rounded : Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularIcon(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), // Dark glassmorphism
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1), // Subtle light border for droplet effect
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
