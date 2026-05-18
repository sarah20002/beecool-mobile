import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'order_tracking_screen.dart';

enum OrderFilter { toutes, enCours, servies }

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  OrderFilter _selectedFilter = OrderFilter.toutes;

  // Static list of orders matching the screenshot exactly
  final List<Map<String, dynamic>> _allOrders = [
    {
      'id': '4829',
      'date': '13 fév · 20:30',
      'status': 'EN PRÉPARATION',
      'mainDish': 'Tajine bar safrané +3 arti...',
      'total': '589,09',
      'isActive': true,
      'remainingItemsCount': 1,
      'foodImages': [
        'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?auto=format&fit=crop&q=80&w=150',
        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=150',
        'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?auto=format&fit=crop&q=80&w=150',
      ],
    },
    {
      'id': '4801',
      'date': '10 fév · 21:15',
      'status': 'SERVIE',
      'mainDish': 'Couscous royal +2 articles',
      'total': '420,00',
      'isActive': false,
      'remainingItemsCount': 0,
      'hasFeedback': true,
      'foodImages': [
        'https://images.unsplash.com/photo-1585238342024-78d387f4a707?auto=format&fit=crop&q=80&w=150',
        'https://images.unsplash.com/photo-1606787366850-de6330128bfc?auto=format&fit=crop&q=80&w=150',
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&q=80&w=150',
      ],
    },
    {
      'id': '4756',
      'date': '02 fév · 13:00',
      'status': 'SERVIE',
      'mainDish': 'Pastilla volaille +1 article',
      'total': '210,00',
      'isActive': false,
      'remainingItemsCount': 0,
      'foodImages': [
        'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&q=80&w=150',
        'https://images.unsplash.com/photo-1598515214211-89d3e73ae83b?auto=format&fit=crop&q=80&w=150',
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    switch (_selectedFilter) {
      case OrderFilter.toutes:
        return _allOrders;
      case OrderFilter.enCours:
        return _allOrders.where((ord) => ord['status'] == 'EN PRÉPARATION' || ord['status'] == 'EN ATTENTE').toList();
      case OrderFilter.servies:
        return _allOrders.where((ord) => ord['status'] == 'SERVIE').toList();
    }
  }

  int get _countToutes => 24; // Keep the total of 24 as in the screenshot
  int get _countEnCours => _allOrders.where((ord) => ord['status'] == 'EN PRÉPARATION' || ord['status'] == 'EN ATTENTE').length;
  int get _countServies => 20; // Keep the total of 20 as in the screenshot

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

              // 3. Content list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: _filteredOrders.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final ord = _filteredOrders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildOrderCard(ord),
                            );
                          },
                          childCount: _filteredOrders.length,
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
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD200), // Warm gold
            Color(0xFFF7971E), // Amber orange
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
          // Background soft geometric overlays
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
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
                          color: Colors.white.withOpacity(0.4),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
                      ),
                    ),
                    
                    const Text(
                      'Mes commandes',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),

                    // Search Button
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: const Icon(Icons.search_rounded, color: Color(0xFF0F172A), size: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // "DÉPENSÉ EN 2026" Text
                const Text(
                  'DÉPENSÉ EN 2026',
                  style: TextStyle(
                    color: Color(0xFF7E7260),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 4),

                // Large "1 609 dh" title
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    const Text(
                      '1 609',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'dh',
                      style: TextStyle(
                        color: const Color(0xFF0F172A).withOpacity(0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Subtitle: 24 commandes • +320 Goûts d'Or gagnés
                const Text(
                  '24 commandes · +320 Goûts d\'Or gagnés',
                  style: TextStyle(
                    color: Color(0xFF5C3F00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          _buildTabItem(OrderFilter.toutes, 'Toutes', _countToutes),
          _buildTabItem(OrderFilter.enCours, 'En cours', _countEnCours),
          _buildTabItem(OrderFilter.servies, 'Servies', _countServies),
        ],
      ),
    );
  }

  Widget _buildTabItem(OrderFilter filter, String label, int count) {
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
            color: isSelected ? const Color(0xFF0A1128) : Colors.transparent, // deep dark blue
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              // Tiny badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFC9910) : const Color(0xFFE2E8F0),
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
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> ord) {
    bool isActive = ord['isActive'] as bool;
    String status = ord['status'] as String;
    List<String> foodImages = List<String>.from(ord['foodImages'] ?? []);
    int remaining = ord['remainingItemsCount'] as int;
    bool hasFeedback = ord['hasFeedback'] ?? false;
    
    // Status colors
    Color statusBgColor;
    Color statusTextColor;
    
    if (status == 'EN PRÉPARATION') {
      statusBgColor = const Color(0xFFFC9910);
      statusTextColor = Colors.white;
    } else {
      statusBgColor = const Color(0xFFE0F2FE);
      statusTextColor = const Color(0xFF0369A1);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFFFC9910) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: #id · Date on left, Status on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#${ord['id']}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ord['date'],
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content: Food Thumbnails + Description text
          Row(
            children: [
              _buildFoodThumbnails(foodImages, remaining),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ord['mainDish'],
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasFeedback) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 12)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Votre avis',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          
          const SizedBox(height: 12),

          // Footer: TOTAL label + value on left, Button on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      Text(
                        ord['total'],
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'dh',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isActive) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderTrackingScreen(orderId: '4829')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1128), // dark blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Suivre',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 14),
                    ],
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0F172A)),
                  label: const Text(
                    'Recommander',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodThumbnails(List<String> urls, int remaining) {
    List<Widget> items = [];
    for (int i = 0; i < urls.length; i++) {
      items.add(
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
            image: DecorationImage(
              image: NetworkImage(urls[i]),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    if (remaining > 0) {
      items.add(
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1128),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '+$remaining',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    
    final double overlapOffset = 24.0;
    return SizedBox(
      width: items.isEmpty ? 0 : (items.length - 1) * overlapOffset + 34.0,
      height: 34,
      child: Stack(
        children: items.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget w = entry.value;
          return Positioned(
            left: idx * overlapOffset,
            child: w,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune commande trouvée',
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
