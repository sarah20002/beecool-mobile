import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'order_tracking_screen.dart';
import 'payment_error_screen.dart';
import 'payment_error_screen.dart';

// ─────────────────────────  Tokens  ─────────────────────────
class BC {
  static const cream     = Color(0xFFFFFFFF);
  static const paper     = Color(0xFFFFFFFF);
  static const ink       = Color(0xFF0E1A2F);
  static const honey     = Color(0xFFF8A11C);
  static const honeyDeep = Color(0xFFDC861A);
  static final textMid   = const Color(0xFF0E1A2F).withOpacity(0.62);
  static final textSoft  = const Color(0xFF0E1A2F).withOpacity(0.40);
  static final hair       = const Color(0xFF0E1A2F).withOpacity(0.07);
  static final hairStrong = const Color(0xFF0E1A2F).withOpacity(0.14);
}

class CardPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String orderId;

  const CardPaymentScreen({
    super.key,
    required this.amount,
    required this.orderId,
    this.currency = 'DT',
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  bool _saveCard = true;
  String _month = '08';
  String _year  = '2027';

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  
  String _cardNumber = "";
  String _cardHolder = "VOTRE NOM ICI";

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
    final amountStr = widget.amount.toStringAsFixed(2).replaceAll('.', ',');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4ED), // Matches form background
      body: Stack(
        children: [
          // 1. Backdrop (Top Dark Area)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 450, // Only cover top area
            child: const _BackdropGlow(),
          ),

          // 2. Main Content (Scrollable)
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  
                  // Overlapping Stack for Card and Form
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // The Form Box (starts lower to overlap)
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
                        child: _buildForm(amountStr),
                      ),

                      // The Virtual Card (on top)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _VisaCardVisual(
                          cardNumber: _cardNumber,
                          cardHolder: _cardHolder,
                        ),
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
          _GlassCircle(
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
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
          const Text(
            'Paiement carte',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _GlassCircle(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentErrorScreen())),
            child: CustomPaint(size: const Size(16, 16), painter: _ShieldCheckPainter()),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(String amountStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(label: 'Numéro de carte', controller: _cardNumberController, hint: '4829 1245 8836 2122'),
        const SizedBox(height: 15),
        _buildField(label: 'Titulaire', controller: _holderController, hint: 'Sarra Ben Ali'),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildDropdown(label: 'Mois', value: _month, items: ['01','02','03','04','05','06','07','08','09','10','11','12'], onChanged: (v) => setState(() => _month = v!))),
            const SizedBox(width: 10),
            Expanded(child: _buildDropdown(label: 'Année', value: _year, items: ['2025','2026','2027','2028','2029','2030','2031','2032'], onChanged: (v) => setState(() => _year = v!))),
            const SizedBox(width: 10),
            SizedBox(width: 80, child: _buildField(label: 'CVV', hint: '•••', isMono: true)),
          ],
        ),
        const SizedBox(height: 20),
        _SaveCardRow(saveCard: _saveCard, onChanged: (v) => setState(() => _saveCard = v)),
        const SizedBox(height: 20),
        _AmountReminder(amount: '$amountStr ${widget.currency}'),
        const SizedBox(height: 25),
        _PayButton(
          label: 'Payer $amountStr ${widget.currency}',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderTrackingScreen(orderId: widget.orderId))),
        ),
      ],
    );
  }

  Widget _buildField({required String label, String? hint, TextEditingController? controller, bool isMono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BC.textMid)),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: BC.hair),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BC.ink, fontFamily: isMono ? 'monospace' : null),
            decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: TextStyle(color: BC.textSoft)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BC.textMid)),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: BC.hair)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────  Sub-Widgets  ─────────────────────────

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B1124), // Solid base for top area
      ),
      child: Stack(
        children: [
          Positioned(right: -80, top: -100, child: _Glow(color: const Color(0x4A6380C8), size: 320)),
          Positioned(left: -100, top: 60, child: _Glow(color: const Color(0x36D63C4F), size: 280)),
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

class _VisaCardVisual extends StatelessWidget {
  final String cardNumber, cardHolder;
  const _VisaCardVisual({required this.cardNumber, required this.cardHolder});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1A1D3D), // Dark Navy base
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Purple Glow Top Right
          Positioned(
            right: -60, top: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFA855F7).withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),
          // 2. Facets
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
                    _Chip(),
                    const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ],
                ),
                _AnimatedCardNumber(cardNumber: cardNumber),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MetaLabel(label: 'TITULAIRE', value: cardHolder.isEmpty ? "FULL NAME" : cardHolder),
                    const _MetaLabel(label: 'EXPIRE', value: '08/27'),
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

class _Chip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 30,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      gradient: const LinearGradient(colors: [Color(0xFFD8C896), Color(0xFF6C5F40)]),
    ),
  );
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
          String finalChar = (isDigit && i > 4 && i < 12) ? "*" : char;
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

class _GlassCircle extends StatelessWidget {
  final Widget child; final VoidCallback? onTap;
  const _GlassCircle({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2))), child: Center(child: child)),
  );
}

class _AmountReminder extends StatelessWidget {
  final String amount;
  const _AmountReminder({required this.amount});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: BC.ink, borderRadius: BorderRadius.circular(15)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('MONTANT', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
      Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _PayButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _PayButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 55,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [BC.honey, BC.honeyDeep]), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: BC.honey.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Center(child: Text(label, style: const TextStyle(color: BC.ink, fontWeight: FontWeight.bold, fontSize: 16))),
    ),
  );
}

class _SaveCardRow extends StatelessWidget {
  final bool saveCard; final ValueChanged<bool> onChanged;
  const _SaveCardRow({required this.saveCard, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Switch(value: saveCard, onChanged: onChanged, activeColor: BC.honey),
      const Expanded(child: Text('Enregistrer cette carte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BC.ink))),
      Text('chiffrée AES-256', style: TextStyle(fontSize: 10, color: BC.textSoft)),
    ],
  );
}

class _ShieldCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2, p);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CardFacetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.04);
    
    // Facet 1 (Top Left)
    final path1 = Path()..moveTo(0, 0)..lineTo(size.width * 0.5, 0)..lineTo(size.width * 0.2, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(path1, p);
    
    // Facet 2 (Diamond in middle)
    final p2 = Paint()..color = Colors.white.withOpacity(0.03);
    final path2 = Path()
      ..moveTo(size.width * 0.4, size.height * 0.1)
      ..lineTo(size.width * 0.7, size.height * 0.4)
      ..lineTo(size.width * 0.4, size.height * 0.8)
      ..lineTo(size.width * 0.1, size.height * 0.4)
      ..close();
    canvas.drawPath(path2, p2);

    // Facet 3 (Bottom Right slant)
    final path3 = Path()..moveTo(size.width, size.height)..lineTo(size.width * 0.6, size.height)..lineTo(size.width * 0.8, 0)..lineTo(size.width, 0)..close();
    canvas.drawPath(path3, p);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
