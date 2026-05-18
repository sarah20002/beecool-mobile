import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';

enum ReservationFilter { toutes, avenir, passees }

class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  ReservationFilter _selectedFilter = ReservationFilter.toutes;

  // Static list of reservations matching the screenshot exactly
  final List<Map<String, dynamic>> _allReservations = [
    {
      'id': '1',
      'branch': 'Beecool · Anfa',
      'status': 'À VENIR',
      'time': '13 fév · 20:30',
      'details': '4 pers · Table 05',
      'dateMonth': 'FÉV',
      'dateDay': '13',
      'dateWeek': 'VEN',
      'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=250',
      'isActive': true,
    },
    {
      'id': '2',
      'branch': 'Beecool · Marina',
      'status': 'EN ATTENTE',
      'time': '21 fév · 13:00',
      'details': '2 pers · Table 12',
      'dateMonth': 'FÉV',
      'dateDay': '21',
      'dateWeek': 'SAM',
      'imageUrl': 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&q=80&w=250',
      'isActive': false,
    },
    {
      'id': '3',
      'branch': 'Beecool · Anfa',
      'status': 'PASSÉE',
      'time': '18 jan · 21:00',
      'details': '6 pers · Table 09',
      'dateMonth': 'JAN',
      'dateDay': '18',
      'dateWeek': 'SAM',
      'imageUrl': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&q=80&w=250',
      'isActive': false,
    },
    {
      'id': '4',
      'branch': 'Beecool · Rabat',
      'status': 'ANNULÉE',
      'time': '02 jan · 20:00',
      'details': '3 pers · Table 03',
      'dateMonth': 'JAN',
      'dateDay': '02',
      'dateWeek': 'VEN',
      'imageUrl': 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&q=80&w=250',
      'isActive': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredReservations {
    switch (_selectedFilter) {
      case ReservationFilter.toutes:
        return _allReservations;
      case ReservationFilter.avenir:
        return _allReservations.where((res) => res['status'] == 'À VENIR' || res['status'] == 'EN ATTENTE').toList();
      case ReservationFilter.passees:
        return _allReservations.where((res) => res['status'] == 'PASSÉE' || res['status'] == 'ANNULÉE').toList();
    }
  }

  int get _countToutes => _allReservations.length;
  int get _countAvenir => _allReservations.where((res) => res['status'] == 'À VENIR' || res['status'] == 'EN ATTENTE').length;
  int get _countPassees => _allReservations.where((res) => res['status'] == 'PASSÉE' || res['status'] == 'ANNULÉE').length;

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
                sliver: _filteredReservations.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final res = _filteredReservations[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildReservationCard(res),
                            );
                          },
                          childCount: _filteredReservations.length,
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
                      'Mes réservations',
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

                // "AU TOTAL" Text
                const Text(
                  'AU TOTAL',
                  style: TextStyle(
                    color: Color(0xFF7E7260),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 4),

                // Large "12 réservations" title
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      '$_countToutes',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'réservations',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Subtitle: 2 à venir • Membre Or depuis 2024
                const Text(
                  '2 à venir · Membre Or depuis 2024',
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
          _buildTabItem(ReservationFilter.toutes, 'Toutes', _countToutes),
          _buildTabItem(ReservationFilter.avenir, 'À venir', _countAvenir),
          _buildTabItem(ReservationFilter.passees, 'Passées', _countPassees),
        ],
      ),
    );
  }

  Widget _buildTabItem(ReservationFilter filter, String label, int count) {
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
            color: isSelected ? const Color(0xFF0A1128) : Colors.transparent, // deep dark blue background
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
              // Tiny round capsule badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFC9910) : const Color(0xFFE2E8F0), // gold if selected, grey if not
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

  Widget _buildReservationCard(Map<String, dynamic> res) {
    bool isActive = res['isActive'] as bool;
    String status = res['status'] as String;
    
    // Status color selection
    Color statusBgColor;
    Color statusTextColor;
    
    if (status == 'À VENIR') {
      statusBgColor = const Color(0xFFFC9910); // amber
      statusTextColor = Colors.white;
    } else if (status == 'EN ATTENTE') {
      statusBgColor = const Color(0xFFE0F2FE); // light blue
      statusTextColor = const Color(0xFF0369A1); // darker blue
    } else if (status == 'PASSÉE') {
      statusBgColor = const Color(0xFFF1F5F9); // light grey
      statusTextColor = const Color(0xFF64748B); // darker grey
    } else {
      statusBgColor = const Color(0xFFFFECEF); // light pink
      statusTextColor = const Color(0xFFD32F2F); // red
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFFFC9910) : Colors.transparent, // amber-gold border around active card
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: Image container with Date overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Network image with premium fade placeholder
                Image.network(
                  res['imageUrl'],
                  width: 75,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Dark glass overlay
                Container(
                  width: 75,
                  height: 75,
                  color: Colors.black.withOpacity(0.35),
                ),
                // Date text container overlay
                SizedBox(
                  width: 75,
                  height: 75,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        res['dateMonth'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        res['dateDay'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        res['dateWeek'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 14),

          // Center: Reservation content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Branch Name & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      res['branch'],
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                
                const SizedBox(height: 6),

                // Time Info
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF94A3B8), size: 13),
                    const SizedBox(width: 5),
                    Text(
                      res['time'],
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),

                // Details Info
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, color: Color(0xFF94A3B8), size: 13),
                    const SizedBox(width: 5),
                    Text(
                      res['details'],
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Right action chevron button (only visible on active cards or as design element)
          if (isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF0A1128), // dark blue button circle
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
            ),
          ],
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
          Icon(Icons.calendar_today_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune réservation trouvée',
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
