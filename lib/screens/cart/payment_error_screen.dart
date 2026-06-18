import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';

class PaymentErrorScreen extends StatelessWidget {
  final double amount;
  const PaymentErrorScreen({super.key, this.amount = 589.09});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4ED),
      body: Stack(
        children: [
          // 1. Backdrop (Top Maroon Area)
          Positioned(
            top: 0, left: 0, right: 0, height: 450,
            child: _RedBackdropGlow(),
          ),

          // 2. Main Content (Scrollable)
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  
                  // Overlapping Stack for Card and Error Info
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // The Error Info Box (starts lower to overlap)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 100),
                        padding: const EdgeInsets.only(top: 110, left: 25, right: 25, bottom: 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4ED),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, -10)),
                          ],
                        ),
                        child: _buildErrorContent(context),
                      ),

                      // The Declined Card (on top)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _DeclinedCardVisual(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: -1),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
          const Text('Paiement', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF451A20), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.3))),
            child: const Row(
              children: [
                CircleAvatar(radius: 3, backgroundColor: Colors.red),
                SizedBox(width: 8),
                Text('ÉCHEC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ERREUR DE TRANSACTION', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        const Text('Paiement non abouti', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'Votre méthode de paiement a été refusée pour '),
              TextSpan(text: '${amount.toStringAsFixed(2).replaceAll('.', ',')} DT', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
              const TextSpan(text: '. Aucun montant n\'a été débité.'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Checklist Box
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('QUE FAIRE ?', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 20),
              _buildCheckItem('1', 'Vérifier votre solde', 'Ou vos plafonds de paiement en ligne'),
              const SizedBox(height: 15),
              _buildCheckItem('2', 'Changer de méthode', 'Essayer une autre carte ou payer sur place'),
              const SizedBox(height: 15),
              _buildCheckItem('3', 'Contacter votre banque', 'Pour lever un éventuel blocage'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Summary Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('À RÉGLER', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('${amount.toStringAsFixed(2).replaceAll('.', ',')} DT', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('NON DÉBITÉ', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        
        // Buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 55,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.grey.shade200)),
                child: const Center(child: Text('Aide', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15))),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF8A11C), Color(0xFFDC861A)]),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Center(child: Text('Réessayer', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15))),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem(String num, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _RedBackdropGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF451A20)),
      child: Stack(
        children: [
          Positioned(right: -50, top: -50, child: _Glow(color: const Color(0xFF6B1B27), size: 300)),
          Positioned(left: -80, top: 100, child: _Glow(color: const Color(0xFF2D1115), size: 280)),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color; final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));
}

class _DeclinedCardVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0xFF4D1A23), Color(0xFF331419)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RedFacetsPainter())),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 38, height: 30, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6))),
                    const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('4829', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    _DeclinedStamp(),
                    const Text('2122', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CardMeta(label: 'TITULAIRE', value: 'SARRA BEN ALI'),
                    _CardMeta(label: 'EXPIRE', value: '08/27'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclinedStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.redAccent.withOpacity(0.8), width: 2),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 10)],
        ),
        child: const Text('DÉCLINÉE', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  final String label, value;
  const _CardMeta({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4), letterSpacing: 1.5)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
    ],
  );
}

class _GlassButton extends StatelessWidget {
  final Widget child; final VoidCallback? onTap;
  const _GlassButton({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3))), child: Center(child: child)))),
  );
}

class _RedFacetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.04);
    final path = Path()..moveTo(0, 0)..lineTo(size.width*0.5, 0)..lineTo(size.width*0.3, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
