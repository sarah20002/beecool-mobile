import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'order_tracking_screen.dart';

class CashPaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  const CashPaymentScreen({super.key, required this.amount, required this.orderId});

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  int _selectedOption = 1; // 1: Serveur, 2: Comptoir

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 16),
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Paiement espèces',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // Top Status Card
            _buildStatusCard(),
            const SizedBox(height: 30),
            
            // Options Row
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    id: 1,
                    icon: Icons.person_outline_rounded,
                    title: 'Auprès du serveur',
                    subtitle: 'Notre équipe passera à votre table pour encaisser.',
                    optionLabel: 'OPTION 1',
                    color: const Color(0xFFF8A11C),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildOptionCard(
                    id: 2,
                    icon: Icons.storefront_rounded,
                    title: 'Au comptoir',
                    subtitle: 'Passez régler en sortant, sans attendre.',
                    optionLabel: 'OPTION 2',
                    color: const Color(0xFF6380C8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Amount Summary Card
            _buildAmountSummaryCard(),
            const SizedBox(height: 40),
            
            // Next Button
            _buildNextButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: -1),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Stack(
        children: [
          // Geometric abstract shapes
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFBBF24), size: 30),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'COMMANDE VALIDÉE',
                      style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'À régler sur place',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900),
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

  Widget _buildOptionCard({
    required int id,
    required IconData icon,
    required String title,
    required String subtitle,
    required String optionLabel,
    required Color color,
  }) {
    bool isSelected = _selectedOption == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E40AF).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MONTANT À RÉGLER',
                style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.amount.toStringAsFixed(2).replaceAll('.', ','),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 5),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('DT', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Text(
              '4 ARTICLES',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderTrackingScreen(orderId: widget.orderId))),
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD97706).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Suivant',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
