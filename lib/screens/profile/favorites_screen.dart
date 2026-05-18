import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';

enum FavoriteFilter { tout, plats, entrees, desserts }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoriteFilter _selectedFilter = FavoriteFilter.tout;

  // Static list of favorites matching the screenshot exactly
  final List<Map<String, dynamic>> _allFavorites = [
    {
      'id': '1',
      'title': 'Tajine de bar safrané',
      'category': 'PLAT',
      'rating': '4.9',
      'orderCount': 'Commandé 3×',
      'price': '240',
      'imageUrl': 'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?auto=format&fit=crop&q=80&w=250',
      'isSpecialBg': true, // orange background as in card 1
    },
    {
      'id': '2',
      'title': 'Pastilla volaille',
      'category': 'ENTRÉE',
      'rating': '4.8',
      'orderCount': 'Commandé 5×',
      'price': '120',
      'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=250',
      'isSpecialBg': false,
    },
    {
      'id': '3',
      'title': 'Crémeux miel d\'Atlas',
      'category': 'DESSERT',
      'rating': '4.9',
      'orderCount': 'Nouveau',
      'price': '65',
      'imageUrl': 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?auto=format&fit=crop&q=80&w=250',
      'isSpecialBg': false,
    },
    {
      'id': '4',
      'title': 'Loup grillé, citron',
      'category': 'PLAT',
      'rating': '4.7',
      'orderCount': 'Commandé 2×',
      'price': '220',
      'imageUrl': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&q=80&w=250',
      'isSpecialBg': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredFavorites {
    switch (_selectedFilter) {
      case FavoriteFilter.tout:
        return _allFavorites;
      case FavoriteFilter.plats:
        return _allFavorites.where((fav) => fav['category'] == 'PLAT').toList();
      case FavoriteFilter.entrees:
        return _allFavorites.where((fav) => fav['category'] == 'ENTRÉE').toList();
      case FavoriteFilter.desserts:
        return _allFavorites.where((fav) => fav['category'] == 'DESSERT').toList();
    }
  }

  int get _countTout => _allFavorites.length;
  int get _countPlats => _allFavorites.where((fav) => fav['category'] == 'PLAT').length;
  int get _countEntrees => _allFavorites.where((fav) => fav['category'] == 'ENTRÉE').length;
  int get _countDesserts => _allFavorites.where((fav) => fav['category'] == 'DESSERT').length;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scrollable CustomScrollView with sticky tabs
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header (without tabs)
              SliverToBoxAdapter(
                child: _buildHeader(statusBarHeight),
              ),

              // 2. Sticky Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  child: _buildFilterTabs(),
                ),
              ),

              // 3. Grid / Content list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: _filteredFavorites.isEmpty
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
                            return _buildFavoriteCard(fav);
                          },
                          childCount: _filteredFavorites.length,
                        ),
                      ),
              ),
            ],
          ),

          // ── Floating Cart FAB ──
          Positioned(
            bottom: 35,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: CustomBottomNav.buildCartFAB(context),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3), // highlight Profile tab
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    return Container(
      height: 240, // Reduced from 290 since tabs are now sticky below
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Background Image taking up the entire header space
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
                  // Dark blend gradient overlay to make text highly legible and elegant
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

          // Large glowing gold heart outline/shadow in background
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
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Glassmorphic Back button
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

                    // Filter settings button
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

                const SizedBox(height: 35),

                // "MES COUPS DE CŒUR" Text
                const Text(
                  'MES COUPS DE CŒUR',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 6),

                // Large "8 plats sauvegardés" title
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    const Text(
                      '8',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'plats sauvegardés',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  '3 restaurants · Re-commandez en un tap',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          _buildTabItem(FavoriteFilter.tout, 'Tout', _countTout),
          _buildTabItem(FavoriteFilter.plats, 'Plats', _countPlats),
          _buildTabItem(FavoriteFilter.entrees, 'Entrées', _countEntrees),
          _buildTabItem(FavoriteFilter.desserts, 'Desserts', _countDesserts),
        ],
      ),
    );
  }

  Widget _buildTabItem(FavoriteFilter filter, String label, int count) {
    bool isSelected = _selectedFilter == filter;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0A1128) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              // Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFC9910) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> fav) {
    bool isSpecialBg = fav['isSpecialBg'] as bool;
    
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
                          fav['imageUrl'],
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
                            fav['rating'],
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
                        fav['category'],
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
                  fav['title'],
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
                  fav['orderCount'],
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
                          fav['price'],
                          style: const TextStyle(
                            color: Color(0xFFFD8A14),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'dh',
                          style: TextStyle(
                            color: Color(0xFFFD8A14),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFD8A14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
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
  double get minExtent => 76.0; // 60 height of tabs + 16 vertical padding
  @override
  double get maxExtent => 76.0;

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
    return false;
  }
}
