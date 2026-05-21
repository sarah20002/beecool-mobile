import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/cart_service.dart';
import '../cart/cart_screen.dart';
import '../home/qr_scanner_screen.dart';

class DishDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dish;
  final bool isEditing;
  final int? cartItemIndex;
  final String? initialNotes;
  final int? initialQuantity;

  const DishDetailScreen({
    super.key,
    required this.dish,
    this.isEditing = false,
    this.cartItemIndex,
    this.initialNotes,
    this.initialQuantity,
  });

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _quantity = 1;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity ?? 1;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
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
    final price = (widget.dish['prix'] as num?)?.toDouble() ?? 0.0;
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
    final description = widget.dish['description'] ?? 'Aucune description disponible pour ce plat raffiné.';
    final imageUrl = (widget.dish['image'] != null && widget.dish['image'].toString().isNotEmpty)
        ? widget.dish['image']
        : 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=400&q=80';
    
    // Ingrédients dynamiques si disponibles
    final List<dynamic> ingredients = widget.dish['ingredients'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(name, priceStr, imageUrl),
                _buildDetailsSection(description),
                if (ingredients.isNotEmpty) _buildIngredientsSection(ingredients),
                _buildSpecialInstructions(),
                const SizedBox(height: 120), // Space for bottom bar
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
                  _circularIcon(Icons.arrow_back, () => Navigator.pop(context)),
                  _circularIcon(Icons.favorite_border, () {}),
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

  Widget _buildHeroImage(String name, String price, String imageUrl) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
              child: const Text('PRODUIT FRAIS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Serif', height: 1.1),
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(color: AppColors.secondary, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(String description) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(List<dynamic> ingredients) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ingrédients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ingredients.map((ing) {
              final ingName = ing['ingredient'] != null ? ing['ingredient']['nom'] : 'Ingrédient';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  ingName,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes spéciales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Allergies ou demandes spécifiques ?',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            // Quantity Selector
            Container(
              height: 56,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(28)),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null)),
                  Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity++)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // Add to Cart Button
            Expanded(
              child: GestureDetector(
                onTap: _addToCart,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.secondary, Color(0xFFD48400)]),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isEditing ? Icons.check_circle_outline_rounded : Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isEditing ? 'Confirmer la modification' : 'Ajouter au panier',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _circularIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
