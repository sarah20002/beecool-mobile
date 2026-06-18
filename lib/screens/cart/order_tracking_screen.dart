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
import 'payment_screen.dart';
import 'dart:async';
import '../../core/services/auth_service.dart';
import '../../core/services/table_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/notification_helper.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:convert';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isClient = false;
  bool _isPaidHistoryExpanded = false;
  StompClient? _stompClient;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    _initStompClient();
  }

  void _initStompClient() {
    // SockJS requires the URL to start with http/https
    String wsUrl = ApiConfig.baseUrl.replaceAll('/api', '/ws');
    
    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        useSockJS: true,
        onConnect: _onConnect,
        beforeConnect: () async {
          debugPrint('Connecting to STOMP WebSocket...');
        },
        onWebSocketError: (dynamic error) => debugPrint('STOMP Error: $error'),
        stompConnectHeaders: {'Authorization': 'Bearer'},
        webSocketConnectHeaders: {'Authorization': 'Bearer'},
      ),
    );
    _stompClient?.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('Connected to STOMP WebSocket');
    _stompClient?.subscribe(
      destination: '/topic/commandes/${widget.orderId}',
      callback: (frame) {
        if (mounted) {
          debugPrint('Received WebSocket update for order: ${widget.orderId}');
          
          if (frame.body != null) {
            try {
              final Map<String, dynamic> payload = jsonDecode(frame.body!);
              if (payload['type'] == 'COMMANDE_UPDATE' && payload['data'] != null) {
                final data = payload['data'];
                final String? itemId = data['itemId']?.toString();
                final String? newStatut = data['statut']?.toString();
                final String? newStatutGlobal = data['statutGlobal']?.toString();
                
                if (itemId != null && newStatut != null && _orderData != null) {
                  setState(() {
                    List<dynamic> activeItems = _orderData!['activeItems'] ?? [];
                    for (var item in activeItems) {
                      if (item['id']?.toString() == itemId) {
                        item['statut'] = newStatut;
                        break;
                      }
                    }
                    if (newStatutGlobal != null) {
                      _orderData!['latestCmdStatus'] = newStatutGlobal;
                      if (newStatutGlobal == 'PRET' || newStatutGlobal == 'SERVIE') {
                        _remainingSeconds = 0;
                        _countdownTimer?.cancel();
                      } else if (newStatutGlobal == 'EN_PREPARATION') {
                        if (!(_countdownTimer?.isActive ?? false)) {
                          _startCountdown();
                        }
                      }
                    }
                  });
                  debugPrint('Updated local item $itemId to $newStatut instantly');
                }
              }
            } catch (e) {
              debugPrint('Error parsing WebSocket payload: $e');
            }
          }

          // Always run _fetchOrderDetails in the background to ensure perfect state sync (timers, etc.)
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _fetchOrderDetails();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
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
        String latestCmdStatus = orderData['statut'] ?? 'EN_ATTENTE';
        // Retrieve all user tickets
        List<Map<String, dynamic>> userTickets = [];
        
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
                  userTickets.add(cmd as Map<String, dynamic>);
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
            userTickets.add(orderData);
            allSessionItems = orderData['items'] as List? ?? [];
          }
        } else {
          userTickets.add(orderData);
          allSessionItems = orderData['items'] as List? ?? [];
        }

        // On sépare les items payés et les items actifs (non payés et non annulés)
        final List<dynamic> paidItems = allSessionItems.where((item) => 
          item['commandeStatut'] == 'PAYEE'
        ).toList();
        
        final List<dynamic> activeItems = allSessionItems.where((item) => 
          item['commandeStatut'] != 'PAYEE' && item['statut'] != 'ANNULE'
        ).toList();
        
        // 🟢 Déduire le statut global en se basant sur TOUS les items actifs
        String deducedStatus = 'EN_ATTENTE';
        
        if (activeItems.isNotEmpty) {
           bool hasEnPrep = activeItems.any((i) => i['statut'] == 'EN_PREPARATION');
           bool hasEnAttente = activeItems.any((i) => i['statut'] == 'EN_ATTENTE');
           bool hasPret = activeItems.any((i) => i['statut'] == 'PRET');
           bool allServi = activeItems.every((i) => i['statut'] == 'SERVI');

           if (hasEnPrep) {
             deducedStatus = 'EN_PREPARATION';
           } else if (hasEnAttente) {
             deducedStatus = 'EN_ATTENTE';
           } else if (hasPret) {
             deducedStatus = 'PRET';
           } else if (allServi) {
             deducedStatus = 'SERVIE';
           }
        } else {
           if (userTickets.any((cmd) => cmd['statut'] == 'PAYEE')) {
               deducedStatus = 'PAYEE';
           } else if (userTickets.any((cmd) => cmd['statut'] == 'SERVIE')) {
               deducedStatus = 'SERVIE';
           } else if (userTickets.isNotEmpty) {
               deducedStatus = userTickets.last['statut'] ?? 'EN_ATTENTE';
           }
        }

        // Calcul du temps de préparation basé sur le plat pertinent
        int calculatedPrepTime = 0;
        String? activeItemIdForTimer;

        if (deducedStatus == 'EN_PREPARATION' || deducedStatus == 'EN_ATTENTE') {
           List<dynamic> targetItems = [];
           if (deducedStatus == 'EN_PREPARATION') {
             targetItems = activeItems.where((i) => i['statut'] == 'EN_PREPARATION').toList();
           } else {
             targetItems = activeItems.where((i) => i['statut'] == 'EN_ATTENTE').toList();
           }
           
           if (targetItems.isNotEmpty) {
             final lastTarget = targetItems.last;
             calculatedPrepTime = lastTarget['tempsPreparation'] ?? 15;
             activeItemIdForTimer = lastTarget['id']?.toString();
           } else {
             calculatedPrepTime = 15;
           }
        }

        // Récupérer le temps écoulé réel depuis le stockage local (SharedPreferences)
        int currentRemainingSeconds = calculatedPrepTime * 60;
        if (activeItemIdForTimer != null) {
           final prefs = await SharedPreferences.getInstance();
           final key = 'item_${activeItemIdForTimer}_prep_started_at';
           
           if (deducedStatus == 'EN_PREPARATION') {
             String? storedTime = prefs.getString(key);
             if (storedTime != null) {
                DateTime startTime = DateTime.parse(storedTime);
                int elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
                currentRemainingSeconds = (calculatedPrepTime * 60) - elapsedSeconds;
                if (currentRemainingSeconds < 0) currentRemainingSeconds = 0;
             } else {
                // Premier passage en préparation pour ce plat spécifique
                await prefs.setString(key, DateTime.now().toIso8601String());
             }
           } else if (deducedStatus == 'EN_ATTENTE') {
             await prefs.remove(key);
           }
        }

        setState(() {
          _isClient = isRealClient;
          _orderData = Map<String, dynamic>.from(orderData);
          _orderData!['items'] = allSessionItems;
          _orderData!['activeItems'] = activeItems;
          _orderData!['paidItems'] = paidItems;
          _orderData!['latestCmdStatus'] = deducedStatus;
          _isLoading = false;
          
          if (calculatedPrepTime == 0 || deducedStatus == 'SERVIE' || deducedStatus == 'PAYEE') {
            _remainingSeconds = 0;
            _countdownTimer?.cancel();
          } else if (deducedStatus == 'EN_ATTENTE') {
            _remainingSeconds = calculatedPrepTime * 60;
            _countdownTimer?.cancel();
          } else if (deducedStatus == 'PRET') {
            _remainingSeconds = 0;
            _countdownTimer?.cancel();
          } else if (deducedStatus == 'EN_PREPARATION') {
            _remainingSeconds = currentRemainingSeconds;
            if (!(_countdownTimer?.isActive ?? false)) {
              _startCountdown();
            }
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
    } else {
      status = _orderData?['latestCmdStatus'] ?? _orderData?['statut'] ?? 'EN_ATTENTE';
      allItemsServi = (status == 'SERVIE' || status == 'PAYEE');
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
                const SizedBox(height: 30),
                if (status != 'PAYEE') _buildPayButton(status),
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

  Widget _buildPayButton(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (status != 'SERVIE') {
              Flushbar(
                message: 'Vous pourrez régler votre addition dès que vos plats seront servis à table.',
                icon: const Icon(Icons.info_outline, size: 28.0, color: Colors.white),
                margin: const EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(8),
                backgroundColor: const Color(0xFFF8A11C),
                duration: const Duration(seconds: 3),
              ).show(context);
            } else {
              double payableAmount = 0.0;
              final List<dynamic> activeItems = _orderData?['activeItems'] ?? [];
              for (var item in activeItems) {
                if (item['statut'] == 'SERVI' && item['paye'] != true) {
                  double price = (item['prixUnitaire'] as num).toDouble();
                  int qty = (item['quantite'] as num).toInt();
                  payableAmount += (price * qty);
                }
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    totalAmount: payableAmount > 0 ? payableAmount : (_orderData?['montantTotal'] ?? 0).toDouble(),
                    orderId: widget.orderId,
                    itemCount: activeItems.where((i) => i['statut'] == 'SERVI' && i['paye'] != true).length,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text('Régler l\'addition', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
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
    String desc = 'État global : votre commande est en attente de validation en cuisine.';
    
    if (status == 'EN_PREPARATION') {
      label = 'En préparation';
      progress = 0.5;
      desc = 'État global : au moins un de vos plats est en cours de préparation.';
    } else if (status == 'PRET') {
      label = 'Prêt';
      progress = 0.8;
      desc = 'État global : vos plats sont prêts et seront servis très bientôt !';
    } else if (status == 'SERVIE') {
      label = 'Servie';
      progress = 1.0;
      desc = 'État global : tous les plats de votre commande ont été servis.';
    } else if (status == 'PAYEE') {
      label = 'Payée';
      progress = 1.0;
      desc = 'État global : commande réglée. Merci et à bientôt chez BeeCool !';
    }

    String countdownStr = '--:--';
    bool showPulsingDot = false;

    if (status == 'PAYEE') {
      countdownStr = 'Réglé';
    } else if (status == 'SERVIE') {
      countdownStr = 'Servi';
    } else if (status == 'PRET') {
      countdownStr = 'Prêt';
    } else if (status == 'EN_ATTENTE') {
      if (remainingSeconds > 0) {
        int minutes = remainingSeconds ~/ 60;
        countdownStr = '~ $minutes min';
      } else {
        countdownStr = '--:--';
      }
    } else if (status == 'EN_PREPARATION') {
      if (remainingSeconds > 0) {
        int minutes = remainingSeconds ~/ 60;
        int seconds = remainingSeconds % 60;
        countdownStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        showPulsingDot = true;
      } else {
        countdownStr = '00:00';
      }
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
                  if (showPulsingDot) ...[
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
    bool enPrepDone = status == 'PRET' || status == 'SERVIE' || status == 'PAYEE';
    bool enPrepActive = status == 'EN_PREPARATION';
    bool pretActive = status == 'PRET';
    bool servieActive = status == 'SERVIE';
    bool servieDone = status == 'SERVIE' || status == 'PAYEE';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ÉTAPES DE VOTRE EXPÉRIENCE', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 25),
          _buildTimelineItem(icon: Icons.check, title: 'Validée', subtitle: 'Reçue à $time', isDone: enAttenteDone),
          _buildTimelineItem(icon: Icons.restaurant_rounded, title: 'En préparation', subtitle: enPrepDone ? 'Cuisine terminée' : (enPrepActive ? 'En cours de cuisson' : 'À venir'), isDone: enPrepDone, isActive: enPrepActive),
          _buildTimelineItem(icon: Icons.room_service_rounded, title: 'Prêt à servir', subtitle: pretActive ? 'En attente du serveur' : (servieDone ? 'Servi' : 'À venir'), isDone: servieDone, isActive: pretActive),
          _buildTimelineItem(icon: Icons.flatware_rounded, title: 'Servi', subtitle: servieActive ? 'Plat sur table' : (status == 'PAYEE' ? 'Terminé' : 'À venir'), isDone: status == 'PAYEE', isActive: servieActive),
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
