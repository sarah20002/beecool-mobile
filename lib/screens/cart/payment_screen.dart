import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'card_payment_screen.dart';
import 'cash_payment_screen.dart';
import 'order_tracking_screen.dart';
import 'payment_error_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/table_service.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String orderId;
  final int itemCount;

  const PaymentScreen({
    super.key, 
    required this.totalAmount, 
    required this.orderId, 
    required this.itemCount
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  bool _utiliserFidelite = true;
  bool _isLoadingData = true;
  bool _hasPromo = false;
  int _clientPoints = 0;
  double _valeurPoint = 0.01;
  double _cautionDisponible = 0.0;
  double _calculatedTotal = 0.0;
  double _realBaseAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculatedTotal = widget.totalAmount;
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
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
      final prefs = await SharedPreferences.getInstance();
      final clientId = prefs.getString('user_id');

      if (clientId != null && clientId.isNotEmpty) {
        final clientRes = await dio.get('/clients/$clientId');
        if (clientRes.statusCode == 200) {
          _clientPoints = clientRes.data['pointsFidelite'] ?? 0;
        }
      }

      final orderRes = await dio.get('/commandes/${widget.orderId}');
      if (orderRes.statusCode == 200) {
        _hasPromo = orderRes.data['hasPromo'] ?? false;
        if (orderRes.data['valeurPointEnDt'] != null) {
          _valeurPoint = (orderRes.data['valeurPointEnDt'] as num).toDouble();
        }
        if (orderRes.data['cautionDisponible'] != null) {
          _cautionDisponible = (orderRes.data['cautionDisponible'] as num).toDouble();
        }
        
        _realBaseAmount = widget.totalAmount;
      }

      if (_hasPromo || _clientPoints <= 0) {
        _utiliserFidelite = false;
      }

      _recalculateTotal();
    } catch (e) {
      debugPrint('Error fetching payment data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _recalculateTotal() {
    double base = _realBaseAmount;
    if (_utiliserFidelite && !_hasPromo && _clientPoints > 0) {
      double discount = _clientPoints * _valeurPoint;
      base -= discount;
    }
    base -= _cautionDisponible;
    _calculatedTotal = base < 0 ? 0 : base;
  }

  @override
  Widget build(BuildContext context) {
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
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 16),
                ),
              ),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.blueGrey, size: 14),
              SizedBox(width: 6),
              Text('SÉCURISÉ', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildPaymentTypeToggle(),
                  const SizedBox(height: 25),
                  if (_selectedMethod == 0) _buildStripeInfoCard(),
                  if (_selectedMethod == 1) _buildCashInfoCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildPaymentSummary(),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: -1),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _summaryRowItem(String label, String value, {bool isSecondary = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: TextStyle(color: textColor ?? (isSecondary ? const Color(0xFF60A5FA) : Colors.white), fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF232A45), 
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMethod = 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedMethod == 0 ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text('En ligne', style: TextStyle(color: _selectedMethod == 0 ? const Color(0xFF1A3673) : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedMethod = 1);
                _showCashPaymentModal(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedMethod == 1 ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text('Espèces', style: TextStyle(color: _selectedMethod == 1 ? const Color(0xFF1A3673) : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF635BFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF635BFF), size: 30),
          ),
          const SizedBox(height: 20),
          const Text(
            'Paiement 100% Sécurisé',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Votre paiement sera traité en toute sécurité par Stripe.\nVous pourrez choisir votre carte bancaire ou Apple/Google Pay à l\'étape suivante.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBrandIcon('https://img.icons8.com/color/48/visa.png'),
              const SizedBox(width: 15),
              _buildBrandIcon('https://img.icons8.com/color/48/mastercard.png'),
              const SizedBox(width: 15),
              _buildBrandIcon('https://img.icons8.com/color/48/apple-pay.png'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCashInfoCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFF8A11C).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8A11C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.money_rounded, color: Color(0xFFF8A11C), size: 30),
          ),
          const SizedBox(height: 20),
          const Text(
            'Paiement sur place',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Réglez votre addition en espèces directement auprès de notre équipe en salle ou au comptoir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandIcon(String url) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
      child: Image.network(url, width: 30, height: 30, errorBuilder: (c, e, s) => const Icon(Icons.credit_card, size: 20)),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RÉCAP COMMANDE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text('${widget.itemCount} ARTICLES', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: Colors.white54,
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                title: const Text('Utiliser mes points', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _hasPromo ? 'Non cumulable avec les promos' : (_clientPoints > 0 ? '$_clientPoints points disponibles' : 'Aucun point disponible'),
                  style: TextStyle(color: _hasPromo ? Colors.redAccent : Colors.white54, fontSize: 10)
                ),
                value: _utiliserFidelite,
                activeColor: const Color(0xFFF8A11C),
                onChanged: (_hasPromo || _clientPoints <= 0) ? null : (val) {
                  setState(() {
                    _utiliserFidelite = val;
                    _recalculateTotal();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _summaryRowItem('Sous-total', '${_realBaseAmount.toStringAsFixed(2)} DT'),
          if (_cautionDisponible > 0)
            _summaryRowItem('Caution déduite', '-${_cautionDisponible.toStringAsFixed(2)} DT', textColor: Colors.greenAccent),
          _summaryRowItem('Service', 'Inclus', isSecondary: true),
          const SizedBox(height: 20),
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Text('Payer maintenant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    if (_selectedMethod == 0) {
                      // Paiement Stripe
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Préparation du paiement...')),
                        );

                        final prefs = await SharedPreferences.getInstance();
                        final currentUserId = prefs.getString('user_id');

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
                        
                        String? safeClientId = currentUserId;
                        if (safeClientId != null && safeClientId.length < 32) {
                          safeClientId = null; // Prevent sending invalid UUIDs
                        }

                        final response = await dio.post('/payments/create-intent-mobile', data: {
                          "sessionId": null,
                          "commandeId": widget.orderId,
                          "perimetre": "MA_COMMANDE",
                          "clientId": safeClientId,
                          "deduireCaution": true,
                          "utiliserFidelite": _utiliserFidelite
                        });

                        final clientSecret = response.data['clientSecret'];
                        final paiementId = response.data['paymentIntentId']; // This is actually the internal Paiement UUID

                        if (clientSecret == "FREE_PAYMENT") {
                          Flushbar(
                            message: 'Paiement validé avec vos avantages ! ✅',
                            icon: const Icon(Icons.check_circle, size: 28.0, color: Colors.white),
                            margin: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(8),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ).show(context);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OrderTrackingScreen(orderId: widget.orderId)));
                          return;
                        }

                        await Stripe.instance.initPaymentSheet(
                          paymentSheetParameters: SetupPaymentSheetParameters(
                            paymentIntentClientSecret: clientSecret,
                            merchantDisplayName: 'BeeCool Restaurant',
                          ),
                        );

                        await Stripe.instance.presentPaymentSheet();

                        // Simuler le Webhook pour localhost (car Stripe ne peut pas contacter votre PC localement)
                        try {
                          String url = '/payments/confirm-mobile/$paiementId';
                          if (safeClientId != null) {
                            url += '?clientId=$safeClientId';
                          }
                          await dio.post(url);
                        } catch (e) {
                          debugPrint('Webhook simulation failed: $e');
                        }

                        Flushbar(
                          message: 'Paiement réussi ✅',
                          icon: const Icon(Icons.check_circle, size: 28.0, color: Colors.white),
                          margin: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ).show(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OrderTrackingScreen(orderId: widget.orderId)));

                      } on DioException catch (e) {
                        debugPrint('Payment Intent creation failed (Dio): ${e.response?.data}');
                        String errorMsg = "Erreur de paiement";
                        if (e.response != null && e.response!.data is Map && e.response!.data['paymentIntentId'] != null) {
                          errorMsg = e.response!.data['paymentIntentId'];
                        }
                        Flushbar(
                          message: errorMsg,
                          icon: const Icon(Icons.error_outline, size: 28.0, color: Colors.white),
                          margin: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: Colors.redAccent,
                          duration: const Duration(seconds: 4),
                        ).show(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaymentErrorScreen(amount: widget.totalAmount)));
                      } catch (e) {
                        debugPrint('Payment Intent creation failed: $e');
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaymentErrorScreen(amount: widget.totalAmount)));
                      }
                    } else {
                      _showCashPaymentModal(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        if (_isLoadingData) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A3673)))
                        else Text('${_calculatedTotal.toStringAsFixed(2)} DT', style: const TextStyle(color: Color(0xFF1A3673), fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A3673), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCashPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CashPaymentModal(
        totalAmount: widget.totalAmount,
        orderId: widget.orderId,
        itemCount: widget.itemCount,
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
              _stepNode('1', isDone: true),
              _stepLine(isActive: true),
              _stepNode('2', isActive: true),
              _stepLine(isActive: false),
              _stepNode('3'),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Panier', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('Paiement', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('Suivi', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
}

class _CashPaymentModal extends StatefulWidget {
  final double totalAmount;
  final String orderId;
  final int itemCount;

  const _CashPaymentModal({
    required this.totalAmount,
    required this.orderId,
    required this.itemCount
  });

  @override
  State<_CashPaymentModal> createState() => _CashPaymentModalState();
}

class _CashPaymentModalState extends State<_CashPaymentModal> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      padding: const EdgeInsets.fromLTRB(25, 12, 25, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFF8A11C), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PAIEMENT ESPÈCES', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const Text('À régler sur place', style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildOption(
            index: 0,
            title: 'Auprès du serveur',
            subtitle: 'Notre équipe passera à votre table pour encaisser.',
          ),
          const SizedBox(height: 15),
          _buildOption(
            index: 1,
            title: 'Au comptoir',
            subtitle: 'Passez régler en sortant, sans attendre.',
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(22)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MONTANT À RÉGLER', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${widget.totalAmount.toStringAsFixed(2)} DT', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF8A11C).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.itemCount} ARTICLES', style: const TextStyle(color: Color(0xFFF8A11C), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => OrderTrackingScreen(orderId: widget.orderId)
                )
              );
            },
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF8A11C), Color(0xFFDC861A)]),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Suivant', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17)),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({required int index, required String title, required String subtitle}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8A11C).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFF8A11C) : Colors.grey.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFF8A11C) : Colors.transparent,
                border: Border.all(color: isSelected ? const Color(0xFFF8A11C) : Colors.grey.shade300, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
