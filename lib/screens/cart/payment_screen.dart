import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'card_payment_screen.dart';
import 'cash_payment_screen.dart';
import 'order_tracking_screen.dart';

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
                  _buildPaymentMethodCard(
                    title: 'Visa • • • • 4829',
                    subtitle: 'Exp. 08/27 · Carte par défaut',
                    logoUrl: 'https://img.icons8.com/color/48/visa.png',
                    isSelected: true,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    title: 'D17 · e-Dinar',
                    subtitle: '+216 22 • • • • 89',
                    logoUrl: 'https://img.icons8.com/color/48/mastercard.png',
                    isSelected: false,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    title: 'Apple Pay',
                    subtitle: 'Face ID · Validation rapide',
                    logoUrl: 'https://img.icons8.com/color/48/apple-pay.png',
                    isSelected: false,
                  ),
                  const SizedBox(height: 20),
                  _buildAddMethodButton(),
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

  Widget _summaryRowItem(String label, String value, {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: TextStyle(color: isSecondary ? const Color(0xFF60A5FA) : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildPaymentMethodCard({required String title, required String subtitle, required String logoUrl, bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? Colors.grey.shade300 : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Image.network(logoUrl, width: 35, height: 35, errorBuilder: (c, e, s) => const Icon(Icons.credit_card)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? AppColors.secondary : Colors.grey.shade300, width: 1.5),
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddMethodButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.add, color: Colors.white, size: 16),
          ),
          SizedBox(width: 15),
          Text('Ajouter un moyen de paiement', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
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
          const SizedBox(height: 20),
          _summaryRowItem('Sous-total', '${widget.totalAmount.toStringAsFixed(2)} DT'),
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
                  onTap: () {
                    if (_selectedMethod == 0) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CardPaymentScreen(amount: widget.totalAmount, orderId: widget.orderId)));
                    } else {
                      _showCashPaymentModal(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        Text('${widget.totalAmount.toStringAsFixed(2)} DT', style: const TextStyle(color: Color(0xFF1A3673), fontWeight: FontWeight.bold, fontSize: 14)),
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
