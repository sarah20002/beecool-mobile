import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/reservation_service.dart';
import 'reservation_confirmation.dart';

class ReservationStep4 extends StatefulWidget {
  final Map<String, dynamic> etablissement;
  final DateTime date;
  final String heure;
  final int nbPersonnes;
  final String nomReservation;
  final String telephone;
  final String email;
  final String demandeSpeciale;
  final int numeroTable;
  final String? tableId;

  const ReservationStep4({
    super.key,
    required this.etablissement,
    required this.date,
    required this.heure,
    required this.nbPersonnes,
    required this.nomReservation,
    required this.telephone,
    required this.email,
    required this.demandeSpeciale,
    required this.numeroTable,
    this.tableId,
  });

  @override
  State<ReservationStep4> createState() => _ReservationStep4State();
}

class _ReservationStep4State extends State<ReservationStep4> {
  String _month = '12';
  String _year  = '2027';
  final TextEditingController _cardNumberController = TextEditingController(text: '4128 1245 8836 4128');
  final TextEditingController _holderController = TextEditingController();
  
  String _cardNumber = "4128 1245 8836 4128";
  String _cardHolder = "";
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cardHolder = widget.nomReservation.toUpperCase();
    _holderController.text = _cardHolder;
    _cardNumberController.addListener(() => setState(() => _cardNumber = _cardNumberController.text));
    _holderController.addListener(() => setState(() => _cardHolder = _holderController.text.toUpperCase()));
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  double get _calculatedCaution {
    final rawPlace = widget.etablissement['montantCautionParPlace'];
    final double amountPerSeat = rawPlace != null ? double.parse(rawPlace.toString()) : 50.0; // default 50 DT/dh
    return amountPerSeat * widget.nbPersonnes;
  }

  Future<void> _submitReservation() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final String monthStr = widget.date.month.toString().padLeft(2, '0');
      final String dayStr = widget.date.day.toString().padLeft(2, '0');
      final String datePart = "${widget.date.year}-$monthStr-$dayStr";
      final String dateHeureStr = "${datePart}T${widget.heure}:00";

      String finalNotes = widget.demandeSpeciale.trim();

      final res = await ReservationService().createReservation(
        etablissementId: widget.etablissement['id'].toString(),
        dateHeure: dateHeureStr,
        nbPersonnes: widget.nbPersonnes,
        nomReservation: widget.nomReservation,
        cautionPayee: true,
        tableId: widget.tableId,
        notes: finalNotes.isNotEmpty ? finalNotes : null,
      );

      if (res != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationConfirmation(
              reservation: res,
              etablissementNom: widget.etablissement['nom'] ?? '',
            ),
          ),
          (route) => false, // Clear all steps stack
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de réservation: ${e.toString().replaceAll("Exception: ", "")}"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), 
                shape: BoxShape.circle, 
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Text('ÉTAPE 4', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                Text(' • /4', style: TextStyle(color: Colors.white60, fontSize: 11)),
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
        
        // --- Formulaire Stripe (Statique / Mockup) ---
        const Text('INFORMATIONS DE CARTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 10),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card_rounded, color: Colors.grey.shade600, size: 22),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w600, letterSpacing: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Numéro de carte',
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(width: 1, height: 25, color: Colors.grey.shade300),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'MM/AA',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(width: 1, height: 25, color: Colors.grey.shade300),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'CVC',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildField(label: 'Titulaire de la carte', controller: _holderController, hint: 'YASMINE BENNIS'),
        
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
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



  Widget _buildPaymentInfoBox() {
    final double cautionVal = _calculatedCaution;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0B1124), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MONTANT BLOQUÉ', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('${cautionVal.toStringAsFixed(2)} DT', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
    final double cautionVal = _calculatedCaution;
    return GestureDetector(
      onTap: _isSubmitting ? null : _submitReservation,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFFF8A11C),
          borderRadius: BorderRadius.circular(32.5),
          boxShadow: [BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Center(
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Color(0xFF0B1124))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint, color: Color(0xFF0B1124), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Confirmer la caution · ${cautionVal.toStringAsFixed(0)} DT',
                      style: const TextStyle(color: Color(0xFF0B1124), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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
                    _MetaLabel(label: 'TITULAIRE', value: cardHolder.isEmpty ? 'TITULAIRE DE CARTE' : cardHolder),
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
