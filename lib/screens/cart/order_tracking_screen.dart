import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../home/home_screen.dart';
import 'review_screen.dart';
import 'cart_screen.dart';
import 'dart:async';
import '../../core/services/auth_service.dart';
import '../../core/services/table_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/notification_helper.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  Timer? _timer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isClient = false;
  bool _isPaidHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    // Rafraîchir toutes les 10 secondes
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOrderDetails();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _countdownTimer?.cancel();
        }
      }
    });
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final isRealClient = email != null && email.isNotEmpty;
      final currentUserId = prefs.getString('user_id');
      final userNom = prefs.getString('user_nom') ?? '';
      final userPrenom = prefs.getString('user_prenom') ?? '';
      final currentUserName = userNom.isNotEmpty ? '$userPrenom $userNom' : '';

      final token = await AuthService().getToken();
      final scanToken = await TableService().getSessionToken();
      final activeToken = token ?? scanToken;

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Platform': 'mobile',
          if (activeToken != null) 'Authorization': 'Bearer $activeToken',
        },
      ));
      final response = await dio.get('/commandes/${widget.orderId}');
      if (response.statusCode == 200 && mounted) {
        final orderData = response.data;
        final String? sessionToken = orderData['sessionToken'];

        List<dynamic> allSessionItems = [];
        
        if (sessionToken != null && sessionToken.isNotEmpty) {
          try {
            final sessionResponse = await dio.get('/commandes/session/$sessionToken');
            if (sessionResponse.statusCode == 200) {
              final List<dynamic> sessionCommands = sessionResponse.data as List;
              for (var cmd in sessionCommands) {
                final String? cmdClientId = cmd['clientId']?.toString();
                final String? cmdClientNom = cmd['clientNom']?.toString();

                bool isOwnOrder = (cmd['id']?.toString() == widget.orderId);

                if (!isOwnOrder) {
                  if (currentUserId != null && currentUserId.isNotEmpty && cmdClientId != null) {
                    isOwnOrder = (cmdClientId == currentUserId);
                  } else if (currentUserName.isNotEmpty && cmdClientNom != null) {
                    isOwnOrder = (cmdClientNom.toLowerCase().trim() == currentUserName.toLowerCase().trim());
                  }
                }

                if (isOwnOrder) {
                  final cmdItems = cmd['items'] as List? ?? [];
                  for (var item in cmdItems) {
                    item['commandeStatut'] = cmd['statut'];
                    allSessionItems.add(item);
                  }
                }
              }
            }
          } catch (sessionErr) {
            debugPrint('Error fetching session commands: $sessionErr');
            allSessionItems = orderData['items'] as List? ?? [];
          }
        } else {
          allSessionItems = orderData['items'] as List? ?? [];
        }

        // On sépare les items payés et les items actifs (non payés et non annulés)
        final List<dynamic> paidItems = allSessionItems.where((item) => 
          item['commandeStatut'] == 'PAYEE'
        ).toList();
        
        final List<dynamic> activeItems = allSessionItems.where((item) => 
          item['commandeStatut'] != 'PAYEE' && item['statut'] != 'ANNULE'
        ).toList();

        // Calcul du temps de préparation sur les items actifs uniquement
        int calculatedPrepTime = 0;
        for (var item in activeItems) {
          if (item['statut'] == 'EN_ATTENTE' || item['statut'] == 'EN_PREPARATION') {
            int itemTime = item['tempsPreparation'] ?? 15;
            if (itemTime > calculatedPrepTime) {
              calculatedPrepTime = itemTime;
            }
          }
        }

        setState(() {
          _isClient = isRealClient;
          _orderData = Map<String, dynamic>.from(orderData);
          _orderData!['items'] = allSessionItems;
          _orderData!['activeItems'] = activeItems;
          _orderData!['paidItems'] = paidItems;
          _isLoading = false;
          
          if (calculatedPrepTime == 0) {
            _remainingSeconds = 0;
            _countdownTimer?.cancel();
          } else if (_remainingSeconds == 0 || (calculatedPrepTime * 60 > _remainingSeconds)) {
            _remainingSeconds = calculatedPrepTime * 60;
            _startCountdown();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.secondary)));
    }

    final activeItems = _orderData?['activeItems'] as List? ?? [];
    final paidItems = _orderData?['paidItems'] as List? ?? [];
    
    // Dynamically deduce the order status from items to ensure perfect consistency
    String status = 'EN_ATTENTE';
    bool allItemsServi = false;
    
    if (activeItems.isEmpty && paidItems.isNotEmpty) {
      status = 'PAYEE';
      allItemsServi = true;
    } else if (activeItems.isNotEmpty) {
      bool anyItemStarted = activeItems.any((item) => 
        item['statut'] == 'EN_PREPARATION' || 
        item['statut'] == 'PRET' || 
        item['statut'] == 'SERVI'
      );
      allItemsServi = activeItems.every((item) => 
        item['statut'] == 'SERVI' || item['statut'] == 'ANNULE'
      );
      
      if (allItemsServi) {
        status = 'SERVIE';
      } else if (anyItemStarted) {
        status = 'EN_PREPARATION';
      } else {
        status = 'EN_ATTENTE';
      }
    } else {
      status = _orderData?['statut'] ?? 'EN_ATTENTE';
    }

    final shortId = widget.orderId.split('-').first.toUpperCase();
    final dateStr = _orderData?['dateCreation'] != null 
        ? _orderData!['dateCreation'].toString().substring(11, 16) 
        : '--:--';

    int totalPrepTime = 0;
    for (var item in activeItems) {
      if (item['statut'] == 'EN_ATTENTE' || item['statut'] == 'EN_PREPARATION') {
        int itemTime = item['tempsPreparation'] ?? 15;
        if (itemTime > totalPrepTime) {
          totalPrepTime = itemTime;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: Stack(
        children: [
          // ─── Content ───
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(shortId, dateStr),
                _buildStepper(status),
                const SizedBox(height: 20),
                _buildCurrentStatusCard(status, _remainingSeconds),
                const SizedBox(height: 35),
                _buildTimelineSection(status, dateStr),
                const SizedBox(height: 35),
                _buildOrderDetailsSection(activeItems, paidItems),
                const SizedBox(height: 120), // BottomNav spacing
              ],
            ),
          ),

          // ─── Glass Header Buttons ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassButton(
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
                _GlassButton(
                  onTap: () {
                    if (_isClient) {
                      if (allItemsServi) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(
                              orderId: widget.orderId,
                              sessionToken: _orderData?['sessionToken'] ?? '',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Vous pourrez évaluer votre commande une fois servie !"))
                        );
                      }
                    } else {
                      NotificationHelper.showWarning(
                        context, 
                        title: "Accès limité", 
                        message: "Veuillez créer un compte pour laisser un avis."
                      );
                    }
                  },
                  child: Icon(
                    Icons.rate_review_rounded, 
                    color: (_isClient && allItemsServi) ? Colors.white : Colors.white.withOpacity(0.5), 
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: -1),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeaderImage(String id, String time) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=1000'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.3), Colors.transparent, const Color(0xFFF9F9F8)],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text('Suivi de Commande', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
            const Text('BEECOOL RESTAURANT', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF8A11C), borderRadius: BorderRadius.circular(20)),
              child: Text('Commande #$id', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 10),
            Text('Passée à $time', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingDot() {
    return Pulse(
      infinite: true,
      duration: const Duration(seconds: 2),
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(String status, int remainingSeconds) {
    String label = 'En attente';
    double progress = 0.2;
    String desc = 'Votre commande a été envoyée en cuisine.';
    
    if (status == 'EN_PREPARATION') {
      label = 'En préparation';
      progress = 0.5;
      desc = 'Le Chef prépare vos mets avec soin...';
    } else if (status == 'SERVIE') {
      label = 'Servie';
      progress = 1.0;
      desc = 'Bon appétit ! Vos plats sont sur table.';
    } else if (status == 'PAYEE') {
      label = 'Payée';
      progress = 1.0;
      desc = 'Table en règle. Merci et à bientôt chez BeeCool !';
    }

    String countdownStr = status == 'PAYEE' ? 'Réglé' : 'Prêt';
    if (remainingSeconds > 0 && status != 'PAYEE') {
      int minutes = remainingSeconds ~/ 60;
      int seconds = remainingSeconds % 60;
      countdownStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ÉTAT ACTUEL', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('ESTIMATION', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFFF8A11C), fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (remainingSeconds > 0) ...[
                    _buildPulsingDot(),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    countdownStr, 
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF8A11C).withOpacity(0.15), borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(widthFactor: progress, child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF8A11C), borderRadius: BorderRadius.circular(3)))),
            ],
          ),
          const SizedBox(height: 15),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
          if (status == 'EN_ATTENTE') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.edit_rounded, color: AppColors.secondary, size: 18),
                label: const Text('ÉDITER LA COMMANDE', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepper(String status) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              _stepNode('1', isDone: true),
              _stepLine(isActive: true),
              _stepNode('2', isDone: true),
              _stepLine(isActive: true),
              _stepNode('3', isActive: true),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Panier', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('Paiement', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('Suivi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepNode(String n, {bool isActive = false, bool isDone = false}) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: (isActive || isDone) ? AppColors.secondary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: (isActive || isDone) ? AppColors.secondary : Colors.grey.shade300),
      ),
      child: Center(
        child: isDone 
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : Text(n, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _stepLine({bool isActive = false}) {
    return Expanded(child: Container(height: 2, color: isActive ? AppColors.secondary : Colors.grey.shade200));
  }

  Widget _buildTimelineSection(String status, String time) {
    bool enAttenteDone = true;
    bool enPrepDone = status == 'SERVIE' || status == 'PAYEE';
    bool enPrepActive = status == 'EN_PREPARATION';
    bool servieActive = status == 'SERVIE';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ÉTAPES DE VOTRE EXPÉRIENCE', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 25),
          _buildTimelineItem(icon: Icons.check, title: 'Validée', subtitle: 'Reçue à $time', isDone: enAttenteDone),
          _buildTimelineItem(icon: Icons.restaurant_rounded, title: 'En préparation', subtitle: enPrepDone ? 'Cuisine terminée' : (enPrepActive ? 'En cours de cuisson' : 'À venir'), isDone: enPrepDone, isActive: enPrepActive),
          _buildTimelineItem(icon: Icons.flatware_rounded, title: 'Servi', subtitle: servieActive ? 'Plat sur table' : 'À venir', isActive: servieActive, isNext: !servieActive && !enPrepDone),
          _buildTimelineItem(icon: Icons.credit_card_rounded, title: 'Payé', subtitle: status == 'PAYEE' ? 'Facture réglée' : 'À régler en fin de repas', isLast: true, isDone: status == 'PAYEE'),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required IconData icon, required String title, required String subtitle, bool isDone = false, bool isActive = false, bool isNext = false, bool isLast = false}) {
    Color mainColor = isDone || isActive ? const Color(0xFFF8A11C) : Colors.grey.shade300;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFF8A11C) : (isActive ? const Color(0xFFF8A11C).withOpacity(0.1) : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(color: mainColor, width: 2),
                  boxShadow: isActive ? [BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                ),
                child: Icon(icon, color: isDone ? Colors.white : (isActive ? const Color(0xFFF8A11C) : Colors.grey.shade400), size: 18),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: mainColor)),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: (isNext && !isActive && !isDone) ? Colors.grey : const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getGroupedItems(List rawItems) {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var item in rawItems) {
      final String platNom = item['platNom'] ?? item['plat']?['nom'] ?? 'Plat';
      final String notes = item['notes'] ?? '';
      final String status = item['statut'] ?? 'EN_ATTENTE';
      final String key = '${platNom}_${status}_${notes}';

      if (grouped.containsKey(key)) {
        grouped[key]!['quantite'] = (grouped[key]!['quantite'] as int) + (item['quantite'] as int);
      } else {
        grouped[key] = {
          'platNom': platNom,
          'quantite': item['quantite'] as int,
          'statut': status,
          'notes': notes,
          'tempsPreparation': item['tempsPreparation'],
          'prixUnitaire': (item['prixUnitaire'] ?? item['prix'] ?? 0.0) as double,
        };
      }
    }
    return grouped.values.toList();
  }

  Widget _buildOrderDetailsSection(List activeItems, List paidItems) {
    final groupedActive = _getGroupedItems(activeItems);
    final groupedPaid = _getGroupedItems(paidItems);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Plats Actifs ---
          const Text('DÉTAILS DE LA COMMANDE', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 20),
          
          if (activeItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: const Center(
                child: Text(
                  'Tous les plats ont été payés avec succès !',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            ...groupedActive.map((item) {
              String statut = item['statut'] ?? 'EN_ATTENTE';
              Color statutColor = Colors.orange;
              if (statut == 'EN_PREPARATION') statutColor = Colors.blue;
              if (statut == 'PRET') statutColor = Colors.green;
              if (statut == 'SERVI') statutColor = AppColors.secondary;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.restaurant, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['platNom'] ?? 'Plat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('${item['quantite']}x · ', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statutColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statut.replaceAll('_', ' '),
                                  style: TextStyle(color: statutColor, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text('${(item['prixUnitaire'] * item['quantite']).toStringAsFixed(2)} DT', style: const TextStyle(color: Color(0xFFF8A11C), fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              );
            }),

          // --- Historique des Plats Payés (Collapsible) ---
          if (paidItems.isNotEmpty) ...[
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPaidHistoryExpanded = !_isPaidHistoryExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'PLATS PAYÉS (${paidItems.length})',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _isPaidHistoryExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
            ),
            if (_isPaidHistoryExpanded) ...[
              const SizedBox(height: 12),
              ...groupedPaid.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.done_all_rounded, color: Colors.green, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['platNom'] ?? 'Plat',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('${item['quantite']}x · ', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'PAYÉ',
                                    style: TextStyle(color: Colors.green, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(item['prixUnitaire'] * item['quantite']).toStringAsFixed(2)} DT',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final Widget child; final VoidCallback? onTap;
  const _GlassButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDisabled ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: isDisabled ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
