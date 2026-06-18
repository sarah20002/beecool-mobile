import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../core/services/reservation_service.dart';
import '../../core/config/api_config.dart';

enum ReservationFilter { toutes, avenir, passees }

class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  ReservationFilter _selectedFilter = ReservationFilter.toutes;
  List<dynamic> _reservations = [];
  Map<String, dynamic> _etablissementMap = {};
  bool _isLoading = true;
  DateTime? _selectedSearchDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Fetch establishments to map details (name, image)
      final dio = Dio();
      final etabRes = await dio.get('${ApiConfig.baseUrl}${ApiConfig.etablissements}');
      if (etabRes.statusCode == 200 && etabRes.data is List) {
        final Map<String, dynamic> tempMap = {};
        for (var etab in etabRes.data) {
          tempMap[etab['id'].toString()] = etab;
        }
        _etablissementMap = tempMap;
      }

      // 2. Fetch user's reservations from backend
      final userReservations = await ReservationService().fetchUserReservations();
      
      _reservations = userReservations;
      // Sort: latest reservation first
      _reservations.sort((a, b) {
        final dtA = DateTime.parse(a['dateHeure']);
        final dtB = DateTime.parse(b['dateHeure']);
        return dtB.compareTo(dtA);
      });
    } catch (e) {
      debugPrint("Erreur lors de la récupération de l'historique : $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredReservations {
    final List<Map<String, dynamic>> mapped = _reservations.map<Map<String, dynamic>>((res) {
      final String id = res['id'].toString();
      final String etabId = res['etablissementId']?.toString() ?? '';
      
      final etab = _etablissementMap[etabId];
      final String branchName = etab != null ? "Beecool · ${etab['nom']}" : "Beecool Restaurant";
      final String imageUrl = (etab != null && etab['image'] != null && etab['image'].toString().isNotEmpty)
          ? etab['image'].toString()
          : 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=250';
      
      final String dateHeureStr = res['dateHeure'] ?? '';
      DateTime dt = DateTime.now();
      if (dateHeureStr.isNotEmpty) {
        try {
          dt = DateTime.parse(dateHeureStr);
        } catch (_) {}
      }

      // Month abbreviation in French
      const months = ['JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUI', 'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC'];
      final String dateMonth = dt.month >= 1 && dt.month <= 12 ? months[dt.month - 1] : 'FÉV';
      final String dateDay = dt.day.toString().padLeft(2, '0');
      
      const weekdays = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
      final String dateWeek = dt.weekday >= 1 && dt.weekday <= 7 ? weekdays[dt.weekday - 1] : 'VEN';

      final String formattedTime = "${dt.day} ${dateMonth.toLowerCase()} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      final String details = "${res['nbPersonnes']} pers${res['numeroTable'] != null ? ' · Table ${res['numeroTable']}' : ''}";

      // Status logic: CONFIRMEE -> À VENIR, EN_ATTENTE -> EN ATTENTE, ANNULEE -> ANNULÉE, date past -> PASSÉE
      final bool isPast = dt.isBefore(DateTime.now());
      String statusLabel = 'À VENIR';
      
      final String apiStatut = res['statut']?.toString()?.toUpperCase() ?? '';
      if (apiStatut == 'ANNULEE' || apiStatut == 'ANNULE') {
        statusLabel = 'ANNULÉE';
      } else if (isPast) {
        statusLabel = 'PASSÉE';
      } else if (apiStatut == 'EN_ATTENTE') {
        statusLabel = 'EN ATTENTE';
      } else {
        statusLabel = 'À VENIR';
      }

      final bool isActive = statusLabel == 'À VENIR' || statusLabel == 'EN ATTENTE';

      return {
        'id': id,
        'rawId': res['id'],
        'branch': branchName,
        'status': statusLabel,
        'time': formattedTime,
        'details': details,
        'dateMonth': dateMonth,
        'dateDay': dateDay,
        'dateWeek': dateWeek,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'montantCaution': res['montantCaution'],
        'cautionPayee': res['cautionPayee'],
        'dateHeureStr': dateHeureStr,
        'clientPrenom': res['clientPrenom'],
        'clientNom': res['clientNom'],
        'nomReservation': res['nomReservation'],
      };
    }).toList();

    List<Map<String, dynamic>> filteredList = mapped;
    if (_selectedSearchDate != null) {
      filteredList = mapped.where((res) {
        final dateStr = res['dateHeureStr'] as String;
        if (dateStr.isEmpty) return false;
        try {
          final dt = DateTime.parse(dateStr);
          return dt.year == _selectedSearchDate!.year &&
                 dt.month == _selectedSearchDate!.month &&
                 dt.day == _selectedSearchDate!.day;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    switch (_selectedFilter) {
      case ReservationFilter.toutes:
        return filteredList;
      case ReservationFilter.avenir:
        return filteredList.where((res) => res['status'] == 'À VENIR' || res['status'] == 'EN ATTENTE').toList();
      case ReservationFilter.passees:
        return filteredList.where((res) => res['status'] == 'PASSÉE' || res['status'] == 'ANNULÉE').toList();
    }
  }

  int get _countToutes => _filteredReservationsCount(ReservationFilter.toutes);
  int get _countAvenir => _filteredReservationsCount(ReservationFilter.avenir);
  int get _countPassees => _filteredReservationsCount(ReservationFilter.passees);

  int _filteredReservationsCount(ReservationFilter filter) {
    final List<Map<String, dynamic>> mapped = _reservations.map<Map<String, dynamic>>((res) {
      final String dateHeureStr = res['dateHeure'] ?? '';
      DateTime dt = DateTime.now();
      if (dateHeureStr.isNotEmpty) {
        try {
          dt = DateTime.parse(dateHeureStr);
        } catch (_) {}
      }
      final bool isPast = dt.isBefore(DateTime.now());
      String statusLabel = 'À VENIR';
      
      final String apiStatut = res['statut']?.toString()?.toUpperCase() ?? '';
      if (apiStatut == 'ANNULEE' || apiStatut == 'ANNULE') {
        statusLabel = 'ANNULÉE';
      } else if (isPast) {
        statusLabel = 'PASSÉE';
      } else if (apiStatut == 'EN_ATTENTE') {
        statusLabel = 'EN ATTENTE';
      } else {
        statusLabel = 'À VENIR';
      }

      return {'status': statusLabel, 'dt': dt};
    }).toList();

    List<Map<String, dynamic>> filteredList = mapped;
    if (_selectedSearchDate != null) {
      filteredList = mapped.where((res) {
        final dt = res['dt'] as DateTime;
        return dt.year == _selectedSearchDate!.year &&
               dt.month == _selectedSearchDate!.month &&
               dt.day == _selectedSearchDate!.day;
      }).toList();
    }

    if (filter == ReservationFilter.toutes) return filteredList.length;
    if (filter == ReservationFilter.avenir) return filteredList.where((res) => res['status'] == 'À VENIR' || res['status'] == 'EN ATTENTE').length;
    return filteredList.where((res) => res['status'] == 'PASSÉE' || res['status'] == 'ANNULÉE').length;
  }

  int get _firstReservationYear {
    if (_reservations.isEmpty) {
      return 2024; // Default fallback
    }
    int oldestYear = DateTime.now().year;
    bool hasValidYear = false;
    for (var res in _reservations) {
      final dateHeureStr = res['dateHeure']?.toString() ?? '';
      if (dateHeureStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(dateHeureStr);
          if (dt.year < oldestYear) {
            oldestYear = dt.year;
            hasValidYear = true;
          }
        } catch (_) {}
      }
    }
    return hasValidYear ? oldestYear : 2024;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFFC9910),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
              sliver: _isLoading
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFC9910),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    )
                  : _filteredReservations.isEmpty
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
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3), // highlight Profile tab
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
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    
                    const Text(
                      'Mes réservations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),

                    // Search Button (Date Filter)
                    GestureDetector(
                      onTap: () async {
                        if (_selectedSearchDate != null) {
                          setState(() => _selectedSearchDate = null);
                        } else {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            helpText: 'SÉLECTIONNER UNE DATE',
                            cancelText: 'ANNULER',
                            confirmText: 'CONFIRMER',
                            fieldLabelText: 'Date de réservation',
                            fieldHintText: 'Jour/Mois/Année',
                            errorFormatText: 'Format invalide.',
                            errorInvalidText: 'Date hors limites.',
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFFFC9910),
                                    onPrimary: Colors.white,
                                    onSurface: Color(0xFF132B49),
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFFC9910),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    backgroundColor: Colors.white,
                                    headerBackgroundColor: const Color(0xFFFC9910),
                                    headerForegroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    headerHelpStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                    headerHeadlineStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _selectedSearchDate = picked);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedSearchDate != null ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: Icon(
                          _selectedSearchDate != null ? Icons.close_rounded : Icons.calendar_month_rounded, 
                          color: Colors.white, 
                          size: 16
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // "AU TOTAL" Text
                Text(
                  'AU TOTAL',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 2),

                // Large reservations count title
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      '$_countToutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'réservations',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Subtitle showing current upcoming reservations
                Text(
                  '$_countAvenir à venir · Membre Or depuis $_firstReservationYear',
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

  Widget _buildReservationCard(Map<String, dynamic> res) {
    bool isActive = res['isActive'] as bool;
    String status = res['status'] as String;
    
    Color statusBgColor;
    Color statusTextColor;
    
    if (status == 'À VENIR') {
      statusBgColor = const Color(0xFFFC9910);
      statusTextColor = Colors.white;
    } else if (status == 'EN ATTENTE') {
      statusBgColor = const Color(0xFFE0F2FE);
      statusTextColor = const Color(0xFF0369A1);
    } else if (status == 'PASSÉE') {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF64748B);
    } else {
      statusBgColor = const Color(0xFFFFECEF);
      statusTextColor = const Color(0xFFD32F2F);
    }

    return GestureDetector(
      onTap: () => _showReservationDetails(res),
      child: Container(
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Left: Image container with Date overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.network(
                    res['imageUrl'],
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                      ),
                      child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24)),
                    ),
                  ),
                  Container(
                    width: 75,
                    height: 75,
                    color: Colors.black.withOpacity(0.35),
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          res['branch'],
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
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
            
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A1128),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReservationDetails(Map<String, dynamic> res) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bool isActive = res['isActive'] as bool;
        final String status = res['status'] as String;
        final double caution = (res['montantCaution'] as num?)?.toDouble() ?? 0.0;
        final bool isCautionPayee = res['cautionPayee'] as bool? ?? false;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      res['branch'],
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFFC9910).withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isActive ? const Color(0xFFFC9910) : Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 20),

              _buildDetailRow(Icons.tag_rounded, "Référence", _getReservationReference(res)),
              const SizedBox(height: 14),
              _buildDetailRow(Icons.calendar_today_rounded, "Date & Heure", res['time']),
              const SizedBox(height: 14),
              _buildDetailRow(Icons.people_alt_rounded, "Invités & Table", res['details']),
              const SizedBox(height: 14),
              _buildDetailRow(
                Icons.security_rounded,
                "Caution de réservation",
                caution > 0
                    ? "${caution.toStringAsFixed(2)} DT (${isCautionPayee ? 'Payée ✅' : 'Non payée ❌'})"
                    : "Aucune caution",
              ),
              
              const SizedBox(height: 30),

              if (isActive) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _confirmCancellation(res['rawId'], res['dateHeureStr']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF2F2),
                      foregroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Annuler ma réservation",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmCancellation(dynamic reservationId, String? dateHeureStr) {
    bool isLessThan24h = false;
    if (dateHeureStr != null && dateHeureStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateHeureStr);
        final diff = dt.difference(DateTime.now());
        if (diff.inHours < 24 && diff.inHours >= 0) {
          isLessThan24h = true;
        }
      } catch (_) {}
    }

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Annuler la réservation ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isLessThan24h
              ? "Êtes-vous sûr de vouloir annuler cette réservation ?\n\n⚠️ Attention : L'annulation à moins de 24h ne sera pas remboursée."
              : "Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible et le remboursement de la caution sera traité sous 24h.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Non, garder", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final int idVal = reservationId is num ? reservationId.toInt() : int.parse(reservationId.toString());
                final success = await ReservationService().cancelReservation(idVal);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Votre réservation a été annulée avec succès."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Une erreur est survenue lors de l'annulation."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll("Exception: ", "")),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Oui, annuler", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
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

  String _getReservationReference(Map<String, dynamic> resa) {
    final String idPart = resa['rawId'] != null ? resa['rawId'].toString().padLeft(4, '0') : '0829';
    
    String fullName = '';
    if (resa['clientPrenom'] != null) {
      fullName = "${resa['clientPrenom']} ${resa['clientNom'] ?? ''}".trim();
    } else if (resa['nomReservation'] != null && resa['nomReservation'].toString().trim().isNotEmpty && resa['nomReservation'].toString() != 'null') {
      fullName = resa['nomReservation'].toString().trim();
    } else {
      fullName = 'Client Inconnu';
    }

    String namePart = fullName.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).join('').toUpperCase();
    String cleanName = namePart.length >= 2 ? namePart.substring(0, 2) : (namePart + 'B').substring(0, 2);
    if (cleanName.length < 2) cleanName = 'CB';

    return "#$cleanName-$idPart-X";
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
