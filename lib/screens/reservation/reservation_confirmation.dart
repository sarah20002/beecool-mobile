import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';

class ReservationConfirmation extends StatelessWidget {
  const ReservationConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _buildTicketCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      height: 480,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8A11C), Color(0xFFFFB347)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HexagonPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.3))),
                        child: const Row(
                          children: [
                            Text('ÉTAPE 5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            Text(' • /5', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130, height: 130,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                        ),
                        Container(
                          width: 95, height: 95,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))]),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF1A2A47), size: 55),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('RÉSERVATION CONFIRMÉE', style: TextStyle(color: Color(0xFF1A2A47), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 15),
                  const Text('La table vous attend,\nYasmine', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1A2A47), fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Serif', height: 1.2)),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard() {
    return FadeInUp(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 15))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFFDEFD9), borderRadius: BorderRadius.circular(10)),
                    child: const Center(child: Text('🐝', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BEECOOL', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Text('Saveurs & Cie · Anfa', style: TextStyle(color: Color(0xFF1A2A47), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFFDEFD9), borderRadius: BorderRadius.circular(12)),
                    child: const Text('#R-4829', style: TextStyle(color: Color(0xFF8B5E14), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            _buildDottedLine(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ticketItem('Date', 'Mer. 15\nmai'),
                  _ticketItem('Heure', '13:00'),
                  _ticketItem('Couverts', '4 pers.'),
                  _ticketItem('Table', 'N° 05'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Color(0xFF1A2A47), fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
      ],
    );
  }

  Widget _buildDottedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFF9F9F8), shape: BoxShape.circle)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: CustomPaint(painter: _DottedPainter()),
            ),
          ),
          Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFF9F9F8), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 30),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text('Calendrier'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A2A47),
                side: BorderSide(color: Colors.grey.shade300),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8A11C),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Retour accueil', style: TextStyle(color: Color(0xFF1A2A47), fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Color(0xFF1A2A47), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.grey.shade300..strokeWidth = 1;
    double dashWidth = 5, dashSpace = 3, startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), p);
      startX += dashWidth + dashSpace;
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.fill;
    canvas.drawPath(_createHexPath(size.width * 0.1, size.height * 0.2, 40), paint);
    canvas.drawPath(_createHexPath(size.width * 0.8, size.height * 0.1, 30), paint);
    canvas.drawPath(_createHexPath(size.width * 0.2, size.height * 0.8, 50), paint);
    canvas.drawPath(_createHexPath(size.width * 0.9, size.height * 0.7, 25), paint);
    final paintDark = Paint()..color = Colors.black.withOpacity(0.05);
    canvas.drawPath(_createHexPath(size.width * 0.5, size.height * 0.4, 120), paintDark);
  }

  Path _createHexPath(double x, double y, double r) {
    final hPath = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * 3.14159 / 180;
      double px = x + r * (i == 0 || i == 3 ? 1 : 0.5);
      // Correction for proper hexagon points
      double cosAngle = (i == 0) ? 1 : (i == 3) ? -1 : (i == 1 || i == 5) ? 0.5 : -0.5;
      double sinAngle = (i == 1 || i == 2) ? 0.866 : (i == 4 || i == 5) ? -0.866 : 0;
      if (i == 0) hPath.moveTo(x + r * cosAngle, y + r * sinAngle);
      else hPath.lineTo(x + r * cosAngle, y + r * sinAngle);
    }
    hPath.close();
    return hPath;
  }

  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
