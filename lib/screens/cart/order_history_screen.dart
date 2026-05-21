import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/services/order_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/notification_helper.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'order_tracking_screen.dart';
import 'review_screen.dart';

enum OrderFilter { toutes, enCours, servies }

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  OrderFilter _selectedFilter = OrderFilter.toutes;
  bool _isRealClient = false;
  List<dynamic> _allOrders = [];
  Map<String, int> _orderRatings = {}; // Map of commandeId -> nbreEtoiles
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkClientAndLoadOrders();
  }

  Future<void> _checkClientAndLoadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('user_id') ?? '';
    if (clientId.isNotEmpty) {
      setState(() {
        _isRealClient = true;
      });
      _loadOrders();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final rawList = await OrderService().getClientOrders();
      
      // Sort: From most recent to oldest
      rawList.sort((a, b) {
        final DateTime dateA = DateTime.tryParse(a['dateCreation']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB = DateTime.tryParse(b['dateCreation']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      // Filter: Only display orders up to one month in the past (30 days)
      final DateTime oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final list = rawList.where((ord) {
        final DateTime date = DateTime.tryParse(ord['dateCreation']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return date.isAfter(oneMonthAgo);
      }).toList();
      
      // Récupérer les feedbacks de ce client pour afficher les étoiles réelles !
      List<dynamic> feedbacks = [];
      try {
        final token = await AuthService().getToken();
        if (token != null) {
          final dio = Dio(BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ));
          final fbResponse = await dio.get('/feedbacks/mes-feedbacks');
          if (fbResponse.statusCode == 200) {
            feedbacks = fbResponse.data as List;
          }
        }
      } catch (fbErr) {
        debugPrint('Error loading feedbacks: $fbErr');
      }

      final Map<String, int> orderRatings = {};
      for (var fb in feedbacks) {
        final String? cmdId = fb['commandeId']?.toString();
        final int? stars = fb['nbreEtoiles'] as int?;
        if (cmdId != null && stars != null) {
          orderRatings[cmdId] = stars;
        }
      }

      if (mounted) {
        setState(() {
          _allOrders = list;
          _orderRatings = orderRatings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredOrders {
    switch (_selectedFilter) {
      case OrderFilter.toutes:
        return _allOrders;
      case OrderFilter.enCours:
        return _allOrders.where((ord) {
          final status = ord['statut']?.toString() ?? '';
          return status == 'EN_ATTENTE' || status == 'EN_PREPARATION';
        }).toList();
      case OrderFilter.servies:
        return _allOrders.where((ord) {
          final status = ord['statut']?.toString() ?? '';
          return status == 'SERVIE' || status == 'PAYEE';
        }).toList();
    }
  }

  int get _countToutes => _allOrders.length;
  
  int get _countEnCours => _allOrders.where((ord) {
        final status = ord['statut']?.toString() ?? '';
        return status == 'EN_ATTENTE' || status == 'EN_PREPARATION';
      }).length;
      
  int get _countServies => _allOrders.where((ord) {
        final status = ord['statut']?.toString() ?? '';
        return status == 'SERVIE' || status == 'PAYEE';
      }).length;

  double get _totalSpent {
    double total = 0.0;
    for (var ord in _allOrders) {
      final double amount = double.tryParse(ord['montantTotal']?.toString() ?? '') ?? 0.0;
      total += amount;
    }
    return total;
  }

  String _formatSpent(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate);
      final months = [
        'janv', 'févr', 'mars', 'avr', 'mai', 'juin', 
        'juil', 'août', 'sept', 'oct', 'nov', 'déc'
      ];
      final monthStr = months[dt.month - 1];
      final minutesStr = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $monthStr · ${dt.hour}:$minutesStr';
    } catch (e) {
      return '';
    }
  }

  String _buildMainDishText(List<dynamic> items) {
    if (items.isEmpty) return 'Aucun article';
    final mainNom = items[0]['platNom'] ?? 'Plat';
    if (items.length > 1) {
      final remain = items.length - 1;
      return '$mainNom +$remain article${remain > 1 ? 's' : ''}';
    }
    return mainNom;
  }

  List<String> _getFoodImages(List<dynamic> items) {
    final fallbacks = [
      'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?auto=format&fit=crop&q=80&w=150',
      'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=150',
      'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?auto=format&fit=crop&q=80&w=150',
      'https://images.unsplash.com/photo-1585238342024-78d387f4a707?auto=format&fit=crop&q=80&w=150',
      'https://images.unsplash.com/photo-1606787366850-de6330128bfc?auto=format&fit=crop&q=80&w=150',
    ];
    
    List<String> urls = [];
    for (int i = 0; i < items.length; i++) {
      if (urls.length >= 3) break;
      
      String? imgUrl;
      final item = items[i];
      if (item is Map) {
        if (item['plat'] != null && item['plat'] is Map && item['plat']['image'] != null) {
          imgUrl = item['plat']['image'].toString();
        } else if (item['platImage'] != null) {
          imgUrl = item['platImage'].toString();
        } else if (item['image'] != null) {
          imgUrl = item['image'].toString();
        }
      }

      if (imgUrl != null && imgUrl.isNotEmpty) {
        urls.add(imgUrl);
      } else {
        final nom = (item is Map ? item['platNom'] : null) ?? '';
        final idx = nom.hashCode.abs() % fallbacks.length;
        urls.add(fallbacks[idx]);
      }
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CircularProgressIndicator(color: Color(0xFFFC9910)),
                      ),
                    ),
                  )
                : _filteredOrders.isEmpty
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
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    return Container(
      height: 240,
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
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    
                    const Text(
                      'Mes commandes',
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
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Text(
                  'DÉPENSÉ EN 2026',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 2),

                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      _formatSpent(_totalSpent),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'DT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  '$_countToutes commandes · +${(_countToutes * 1.5).toInt()} Goûts d\'Or gagnés',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
            color: isSelected ? const Color(0xFF132B49) : Colors.transparent,
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
    final status = ord['statut']?.toString() ?? 'EN_ATTENTE';
    final bool isActive = status == 'EN_ATTENTE' || status == 'EN_PREPARATION';
    
    final itemsList = ord['items'] as List<dynamic>? ?? [];
    final List<String> foodImages = _getFoodImages(itemsList);
    final int remaining = itemsList.length > 3 ? itemsList.length - 3 : 0;
    
    // Status colors mapping
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel = 'EN ATTENTE';

    if (status == 'EN_PREPARATION') {
      statusBgColor = const Color(0xFFFC9910);
      statusTextColor = Colors.white;
      statusLabel = 'EN PRÉPARATION';
    } else if (status == 'SERVIE') {
      statusBgColor = const Color(0xFFE0F2FE);
      statusTextColor = const Color(0xFF0369A1);
      statusLabel = 'SERVIE';
    } else if (status == 'PAYEE') {
      statusBgColor = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF15803D);
      statusLabel = 'PAYÉE';
    } else if (status == 'ANNULEE') {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF64748B);
      statusLabel = 'ANNULÉE';
    } else {
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
      statusLabel = 'EN ATTENTE';
    }

    final double priceVal = double.tryParse(ord['montantTotal']?.toString() ?? '') ?? 0.0;
    final String formattedPrice = _formatSpent(priceVal);

    // Simple display ID
    final String rawId = ord['id']?.toString() ?? '';
    final String displayId = rawId.length > 4 ? rawId.substring(rawId.length - 4) : rawId;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#$displayId',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(ord['dateCreation']?.toString()),
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
                  statusLabel,
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

          Row(
            children: [
              _buildFoodThumbnails(foodImages, remaining),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buildMainDishText(itemsList),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Feedback / Star rating
              Expanded(
                child: _buildFeedbackWidget(rawId, status, ord),
              ),
              
              // Right: Total Price and optional Suivre button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
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
                            formattedPrice,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'DT',
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
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderTrackingScreen(orderId: rawId)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1128),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackWidget(String rawId, String status, Map<String, dynamic> ord) {
    final int? rating = _orderRatings[rawId];
    final bool hasRating = rating != null;
    final bool isCompleted = status == 'SERVIE' || status == 'PAYEE';

    if (hasRating) {
      return Row(
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star_rounded,
                color: index < rating ? Colors.amber : Colors.grey.shade300,
                size: 14,
              );
            }),
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
      );
    } else if (isCompleted) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewScreen(
                orderId: rawId,
                sessionToken: ord['sessionToken'] ?? '',
              ),
            ),
          ).then((_) => _loadOrders());
        },
        child: Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star_border_rounded,
                  color: Colors.grey.shade400,
                  size: 14,
                );
              }),
            ),
            const SizedBox(width: 6),
            const Text(
              'Laisser un avis',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      );
    } else {
      return Row(
        children: [
          Icon(
            status == 'ANNULEE' ? Icons.cancel_outlined : Icons.info_outline,
            color: const Color(0xFF94A3B8),
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            status == 'ANNULEE' ? 'Commande annulée' : 'En cours de préparation',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
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
            _isRealClient 
                ? 'Aucune commande trouvée' 
                : 'Veuillez vous connecter pour voir l\'historique',
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
  double get minExtent => 76.0;
  @override
  double get maxExtent => 76.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
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
