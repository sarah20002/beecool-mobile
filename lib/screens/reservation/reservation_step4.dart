import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import 'reservation_confirmation.dart';

class ReservationStep4 extends StatefulWidget {
  const ReservationStep4({super.key});

  @override
  State<ReservationStep4> createState() => _ReservationStep4State();
}

class _ReservationStep4State extends State<ReservationStep4> {
  String _month = '12';
  String _year  = '2027';
  final TextEditingController _cardNumberController = TextEditingController(text: '4128 1245 8836 4128');
  final TextEditingController _holderController = TextEditingController(text: 'YASMINE BENNIS');
  
  String _cardNumber = "4128 1245 8836 4128";
  String _cardHolder = "YASMINE BENNIS";

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(() => setState(() => _cardNumber = _cardNumberController.text));
    _holderController.addListener(() => setState(() => _cardHolder = _holderController.text.toUpperCase()));
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 400,
            child: Container(color: const Color(0xFF0B1124)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 100),
                        padding: const EdgeInsets.only(top: 110, left: 25, right: 25, bottom: 40),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9F9F8),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                        ),
                        child: _buildForm(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _VisaCardVisual(cardNumber: _cardNumber, cardHolder: _cardHolder),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Text('ÉTAPE 4', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                Text(' • /5', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ÉTAPE 4 · CAUTION', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        const Text('Pré-autorisation', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
        const SizedBox(height: 8),
        const Text('Aucun débit immédiat — libérée 24 h après votre venue.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 30),
        _buildField(label: 'Numéro de carte', controller: _cardNumberController, hint: '4128 1245 8836 4128', isCard: true),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildDropdown(label: 'Mois', value: _month, items: ['01','12'], onChanged: (v) => setState(() => _month = v!))),
            const SizedBox(width: 15),
            Expanded(child: _buildDropdown(label: 'Année', value: _year, items: ['2027','2028'], onChanged: (v) => setState(() => _year = v!))),
            const SizedBox(width: 15),
            SizedBox(width: 100, child: _buildField(label: 'CVV', hint: '•••')),
          ],
        ),
        const SizedBox(height: 30),
        _buildPaymentInfoBox(),
        const SizedBox(height: 30),
        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildField({required String label, String? hint, TextEditingController? controller, bool isCard = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 10),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(hintText: hint, border: InputBorder.none),
                ),
              ),
              if (isCard) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF1A1D3D), borderRadius: BorderRadius.circular(5)),
                child: const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 10),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0B1124), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MONTANT BLOQUÉ', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 8),
              Text('200,00 dh', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Text('NON DÉBITÉ', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReservationConfirmation())),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFFF8A11C),
          borderRadius: BorderRadius.circular(32.5),
          boxShadow: [BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, color: Color(0xFF0B1124), size: 20),
              SizedBox(width: 12),
              Text('Confirmer la caution · 200 dh', style: TextStyle(color: Color(0xFF0B1124), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisaCardVisual extends StatelessWidget {
  final String cardNumber, cardHolder;
  const _VisaCardVisual({required this.cardNumber, required this.cardHolder});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1A1D3D),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -60, top: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFA855F7).withOpacity(0.6), Colors.transparent])),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _CardFacetsPainter())),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 38, height: 30, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: [Color(0xFFD8C896), Color(0xFF6C5F40)]))),
                    const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ],
                ),
                _AnimatedCardNumber(cardNumber: cardNumber),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MetaLabel(label: 'TITULAIRE', value: cardHolder),
                    const _MetaLabel(label: 'EXPIRE', value: '12/27'),
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

class _AnimatedCardNumber extends StatelessWidget {
  final String cardNumber;
  const _AnimatedCardNumber({required this.cardNumber});

  @override
  Widget build(BuildContext context) {
    String display = cardNumber.replaceAll(" ", "").padRight(16, "#");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (g) => Row(
        children: List.generate(4, (c) {
          int i = g * 4 + c;
          String char = display[i];
          bool isDigit = char != "#";
          String finalChar = (isDigit && i > 3 && i < 12) ? "*" : char;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (w, a) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(a),
              child: FadeTransition(opacity: a, child: w),
            ),
            child: Text(finalChar, key: ValueKey("$i-$finalChar"), style: TextStyle(color: isDigit ? Colors.white : Colors.white24, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          );
        }),
      )),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final String label, value;
  const _MetaLabel({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.5), letterSpacing: 1.5)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
    ],
  );
}

class _CardFacetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.04);
    final path1 = Path()..moveTo(0, 0)..lineTo(size.width * 0.5, 0)..lineTo(size.width * 0.2, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(path1, p);
    final path3 = Path()..moveTo(size.width, size.height)..lineTo(size.width * 0.6, size.height)..lineTo(size.width * 0.8, 0)..lineTo(size.width, 0)..close();
    canvas.drawPath(path3, p);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
