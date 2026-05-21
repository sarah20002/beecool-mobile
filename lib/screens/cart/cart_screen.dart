import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/config/api_config.dart';
import '../home/home_screen.dart';
import '../menu/menu_screen.dart';
import '../menu/dish_detail_screen.dart';
import 'payment_screen.dart';
import 'order_tracking_screen.dart';
import '../../core/services/table_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/notification_helper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  bool _isSubmitting = false;
  List<dynamic> _serverOrders = [];
  bool _isLoadingOrders = false;
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartChanged);
    _fetchServerOrders();
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchServerOrders() async {
    final token = _cartService.sessionToken;
    if (token == null) return;

    setState(() => _isLoadingOrders = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');
      final userNom = prefs.getString('user_nom') ?? '';
      final userPrenom = prefs.getString('user_prenom') ?? '';
      _currentUserName = userNom.isNotEmpty ? '$userPrenom $userNom' : '';

      final jwtToken = await AuthService().getToken();
      final scanToken = await TableService().getSessionToken();
      final activeToken = jwtToken ?? scanToken;

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Platform': 'mobile',
          if (activeToken != null) 'Authorization': 'Bearer $activeToken',
        },
      ));
      final response = await dio.get('/commandes/session/$token');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _serverOrders = response.data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  void _navigateToMenu() {
    final etablissementId = _cartService.etablissementId;
    final sessionToken = _cartService.sessionToken;

    if (etablissementId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuScreen(
            etablissementId: etablissementId,
            sessionToken: sessionToken,
          ),
        ),
      );
    } else {
      // Fallback to HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _submitOrder({String? guestName}) async {
    if (_cartService.items.isEmpty) return;
    
    if (_cartService.sessionToken == null) {
      NotificationHelper.showWarning(
        context, 
        title: "Session requise", 
        message: "Veuillez d'abord scanner une table."
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');
      final isRealClient = userEmail != null && userEmail.isNotEmpty;
      
      String? resolvedGuestName = guestName;
      if (!isRealClient && (resolvedGuestName == null || resolvedGuestName.isEmpty)) {
        resolvedGuestName = prefs.getString('user_prenom') ?? 'Invite';
      }
      final clientId = isRealClient ? prefs.getString('user_id') : prefs.getString('guest_id');

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

      // L'invité a déjà été enregistré lors du scan QR, aucune duplication requise.

      final orderData = {
        'sessionToken': _cartService.sessionToken,
        if (!isRealClient && resolvedGuestName != null && resolvedGuestName.isNotEmpty) 'nomInvite': resolvedGuestName,
        if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
        'items': _cartService.items.map((item) => item.toJson()).toList(),
      };

      final response = await dio.post('/commandes', data: orderData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderDataResponse = response.data;
        _cartService.clear();
        
        if (mounted) {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                totalAmount: (orderDataResponse['montantTotal'] as num).toDouble(),
                orderId: orderDataResponse['id'],
                itemCount: (orderDataResponse['items'] as List).length,
              )
            )
          );
        }
      }
    } catch (e) {
      String msg = 'Erreur lors de la commande.';
      if (e is DioException && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map) {
          msg = resData['message'] ?? msg;
        } else if (resData is String) {
          msg = resData;
        }
      }
      if (mounted) {
        NotificationHelper.showError(
          context, 
          title: "Échec de la commande", 
          message: msg,
          onRetry: () => _submitOrder()
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showGuestNameModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: AppColors.secondary, size: 24),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRÉPARATION EN CUISINE',
                              style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            Text(
                              'Votre prénom / table',
                              style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: AppColors.primary, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Entrez votre prénom ou le nom de votre groupe afin que nous puissions identifier vos plats à la caisse.',
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre prénom';
                        }
                        if (value.trim().length < 2) {
                          return 'Le prénom doit contenir au moins 2 caractères';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Ex: Sarra, Table 4, Invité...',
                        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      if (formKey.currentState!.validate()) {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        _submitOrder(guestName: nameController.text.trim());
                      }
                    },
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.secondary, Color(0xFFDC861A)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirmer et commander',
                              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.check_rounded, color: Color(0xFF0F172A), size: 16),
                          ],
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final items = _cartService.items;
    final serverItems = _getGroupedServerItems();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 80,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 18),
            ),
          ),
        ),
        title: const Text(
          'Mon Panier',
          style: TextStyle(color: AppColors.primary, fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchServerOrders,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: (items.isEmpty && serverItems.isEmpty)
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Return to menu button above the lists
                        if (items.isNotEmpty || serverItems.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: GestureDetector(
                              onTap: _navigateToMenu,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.secondary, size: 12),
                                    SizedBox(width: 8),
                                    Text(
                                      'Retourner au menu / Ajouter des plats',
                                      style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (items.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'ARTICLES À CONFIRMER',
                            style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 20),
                          ...items.asMap().entries.map((entry) => _buildCartItem(
                            index: entry.key,
                            item: entry.value,
                          )),
                        ],
                        if (serverItems.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          const Text(
                            'COMMANDES EN CUISINE (CONFIRMÉES)',
                            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 20),
                          ...serverItems.map((item) => _buildServerItem(item)),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
          if (items.isNotEmpty) 
            _buildPaymentRecap()
          else if (serverItems.isNotEmpty)
            _buildTrackingReturnButton(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getGroupedServerItems() {
    final List<dynamic> allItems = [];
    for (var order in _serverOrders) {
      final String orderStatut = order['statut'] ?? 'EN_ATTENTE';
      
      final String? cmdClientId = order['clientId']?.toString();
      final String? cmdClientNom = order['clientNom']?.toString();
      
      bool isOwnOrder = false;
      if (_currentUserId != null && _currentUserId!.isNotEmpty && cmdClientId != null) {
        isOwnOrder = (cmdClientId == _currentUserId);
      } else if (_currentUserName != null && _currentUserName!.isNotEmpty && cmdClientNom != null) {
        isOwnOrder = (cmdClientNom.toLowerCase().trim() == _currentUserName!.toLowerCase().trim());
      } else {
        isOwnOrder = true; // fallback
      }

      if (isOwnOrder) {
        for (var item in order['items']) {
          final Map<String, dynamic> itemCopy = Map<String, dynamic>.from(item);
          if (itemCopy['statut'] == null) {
            itemCopy['statut'] = orderStatut;
          }
          allItems.add(itemCopy);
        }
      }
    }

    final Map<String, Map<String, dynamic>> grouped = {};
    for (var item in allItems) {
      final String platNom = item['platNom'] ?? item['plat']?['nom'] ?? 'Plat';
      final String notes = item['notes'] ?? '';
      final String status = item['statut'] ?? 'EN_ATTENTE';
      final String key = '${platNom}_${status}_${notes}';

      if (grouped.containsKey(key)) {
        grouped[key]!['quantite'] = (grouped[key]!['quantite'] as int) + (item['quantite'] as int);
        (grouped[key]!['ids'] as List<String>).add(item['id'].toString());
      } else {
        grouped[key] = {
          'id': item['id'].toString(),
          'ids': [item['id'].toString()],
          'platNom': platNom,
          'quantite': item['quantite'] as int,
          'statut': status,
          'notes': notes,
          'prixUnitaire': (item['prixUnitaire'] ?? item['prix'] ?? 0.0) as double,
        };
      }
    }
    return grouped.values.toList();
  }

  Future<void> _updateServerItemQuantity(dynamic itemIdOrList, int newQty, int currentQty) async {
    final List<String> ids = itemIdOrList is List 
        ? List<String>.from(itemIdOrList) 
        : [itemIdOrList.toString()];

    if (newQty <= 0) {
      _deleteServerItem(ids);
      return;
    }

    try {
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

      final String targetId = ids.first;
      int targetItemCurrentQty = 1;
      outer:
      for (var order in _serverOrders) {
        for (var item in order['items']) {
          if (item['id'].toString() == targetId) {
            targetItemCurrentQty = item['quantite'] ?? 1;
            break outer;
          }
        }
      }

      int diff = newQty - currentQty;
      int targetItemNewQty = targetItemCurrentQty + diff;

      if (targetItemNewQty <= 0) {
        await dio.delete('/commandes/items/$targetId');
      } else {
        await dio.put('/commandes/items/$targetId?quantite=$targetItemNewQty');
      }
      _fetchServerOrders();
    } catch (e) {
      debugPrint('Error updating server item: $e');
    }
  }

  Future<void> _deleteServerItem(dynamic itemIdOrList) async {
    try {
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

      final List<String> ids = itemIdOrList is List 
          ? List<String>.from(itemIdOrList) 
          : [itemIdOrList.toString()];

      for (String id in ids) {
        await dio.delete('/commandes/items/$id');
      }
      _fetchServerOrders();
    } catch (e) {
      debugPrint('Error deleting server item: $e');
    }
  }

  Widget _buildServerItem(Map<String, dynamic> item) {
    String statut = item['statut'] ?? 'EN_ATTENTE';
    Color statutColor = Colors.orange;
    if (statut == 'EN_PREPARATION') statutColor = Colors.blue;
    if (statut == 'PRET') statutColor = Colors.green;
    if (statut == 'SERVI') statutColor = AppColors.secondary;

    bool isEditable = statut == 'EN_ATTENTE';
    dynamic itemId = item['ids'] ?? item['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['platNom'] ?? 'Plat', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                const SizedBox(height: 6),
                if (isEditable)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade100)),
                        child: Row(
                          children: [
                            _qtyBtn(Icons.remove, () => _updateServerItemQuantity(itemId, item['quantite'] - 1, item['quantite'])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('${item['quantite']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            _qtyBtn(Icons.add, () => _updateServerItemQuantity(itemId, item['quantite'] + 1, item['quantite']), isAdd: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => _deleteServerItem(itemId),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        ),
                      ),
                    ],
                  )
                else
                  Text('Quantité : ${item['quantite']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statutColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statut.replaceAll('_', ' '),
              style: TextStyle(color: statutColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 70, color: AppColors.secondary),
            ),
            const SizedBox(height: 25),
            const Text(
              'Votre panier est vide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Serif', color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Découvrez notre carte et ajoutez vos plats favoris en un instant !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _navigateToMenu,
              child: Container(
                height: 55,
                width: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.secondary, Color(0xFFDC861A)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Découvrir le Menu', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(width: 8),
                      Icon(Icons.restaurant_menu_rounded, color: Color(0xFF0F172A), size: 16),
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

  Widget _buildStepper() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              _stepNode('1', isActive: true),
              _stepLine(isActive: true),
              _stepNode('2'),
              _stepLine(),
              _stepNode('3'),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Panier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('Paiement', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('Suivi', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepNode(String n, {bool isActive = false}) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? AppColors.secondary : Colors.grey.shade300),
      ),
      child: Center(
        child: Text(n, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _stepLine({bool isActive = false}) {
    return Expanded(child: Container(height: 2, color: isActive ? AppColors.secondary : Colors.grey.shade200));
  }

  Widget _buildCartItem({required int index, required CartItem item}) {
    return FadeInUp(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DishDetailScreen(
                dish: {
                  'id': item.id,
                  'nom': item.name,
                  'prix': item.price,
                  'image': item.imageUrl,
                },
                isEditing: true,
                cartItemIndex: index,
                initialNotes: item.notes,
                initialQuantity: item.quantity,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(item.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14, fontFamily: 'Serif')),
                        Text('${(item.price * item.quantity).toStringAsFixed(2)} DT', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 14)),
                      ],
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.notes, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade100)),
                          child: Row(
                            children: [
                              _qtyBtn(Icons.remove, () => _cartService.updateQuantity(index, -1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              _qtyBtn(Icons.add, () => _cartService.updateQuantity(index, 1), isAdd: true),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _cartService.removeItem(index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: isAdd ? AppColors.secondary : Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade100)),
        child: Icon(icon, color: isAdd ? Colors.white : Colors.grey, size: 14),
      ),
    );
  }

  Widget _buildPaymentRecap() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(20),
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF232A45),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryRowRecap('Total commande', '${_cartService.total.toStringAsFixed(2)} DT'),
              const SizedBox(height: 10),
              _summaryRowRecap('Frais de service', 'Inclus', isSecondary: true),
              const SizedBox(height: 25),
              GestureDetector(
                onTap: _isSubmitting ? null : () async {
                  final token = await AuthService().getToken();
                  if (token != null && token.isNotEmpty) {
                    _submitOrder();
                  } else {
                    _showGuestNameModal(context);
                  }
                },
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _isSubmitting 
                      ? const CircularProgressIndicator(color: Color(0xFF1A3673))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Passer la commande', style: TextStyle(color: Color(0xFF1A3673), fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A3673), size: 20),
                          ],
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRowRecap(String label, String value, {bool isSecondary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
        Text(
          value, 
          style: TextStyle(
            color: isSecondary ? const Color(0xFF60A5FA) : Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 16
          )
        ),
      ],
    );
  }

  Widget _buildTrackingReturnButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(20),
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF232A45),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              if (_serverOrders.isNotEmpty) {
                final activeOrderId = _serverOrders.first['id'].toString();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderTrackingScreen(orderId: activeOrderId),
                  ),
                );
              }
            },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, color: Color(0xFF1A3673), size: 20),
                    SizedBox(width: 10),
                    Text('Suivre ma commande', style: TextStyle(color: Color(0xFF1A3673), fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A3673), size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
