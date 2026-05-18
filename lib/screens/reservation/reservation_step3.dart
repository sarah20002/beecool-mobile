import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import 'reservation_step4.dart';
import '../reservation/reservation_confirmation.dart';

class ReservationStep3 extends StatefulWidget {
  const ReservationStep3({super.key});

  @override
  State<ReservationStep3> createState() => _ReservationStep3State();
}

class _ReservationStep3State extends State<ReservationStep3> {
  String _selectedZone = 'Salle';
  int _selectedTable = -1;

  static const Color vibrantNavy = Color(0xFF1A2A47);
  static const Color colorFree = Color(0xFF4CAF50);
  static const Color colorSelected = AppColors.secondary;
  static const Color colorOccupied = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildCustomHeader(context),
          const SizedBox(height: 10),
          _buildCompactZoneTabs(),
          const SizedBox(height: 15),
          _buildLegendRow(),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: _buildFloorPlanBox(),
            ),
          ),
          if (_selectedTable != -1)
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _buildSelectedTableCard(),
            ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(25, MediaQuery.of(context).padding.top + 10, 25, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2A47), size: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: const Row(
              children: [
                Text('ÉTAPE 3', style: TextStyle(color: Color(0xFF1A2A47), fontWeight: FontWeight.bold, fontSize: 12)),
                Text('  •  /5', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCompactZoneTabs() {
    final zones = ['Salle', 'Terrasse', 'Bar', 'Privée'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: zones.map((z) {
          bool isSelected = _selectedZone == z;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedZone = z;
              _selectedTable = -1;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? vibrantNavy : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [if (isSelected) BoxShadow(color: vibrantNavy.withOpacity(0.2), blurRadius: 10)],
                border: Border.all(color: isSelected ? vibrantNavy : Colors.grey.shade100),
              ),
              child: Text(z, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _legendItem(colorFree, 'Libre'),
          _legendItem(colorSelected, 'Sélection'),
          _legendItem(colorOccupied, 'Occupée'),
        ],
      ),
    );
  }

  Widget _buildFloorPlanBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F8), // Blanc sale / Off-white
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white, width: 2), // 3D edge effect
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, -5)), // Highlight for 3D
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: vibrantNavy, borderRadius: BorderRadius.circular(15)),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, color: AppColors.secondary, size: 16),
                  SizedBox(width: 10),
                  Text('PLAN DE LA SALLE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 35),
          Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_table(1), _table(2, isOccupied: true)]),
              const SizedBox(height: 35),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_table(4), _table(5), _table(6)]),
              const SizedBox(height: 35),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [_table(7, isLarge: true, isOccupied: true)]),
              const SizedBox(height: 25),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [_table(8)]),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _table(int num, {bool isOccupied = false, bool isLarge = false}) {
    bool isSelected = _selectedTable == num;
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color iconColor = colorFree;
    if (isSelected) {
      bgColor = colorSelected;
      borderColor = colorSelected;
      iconColor = Colors.white;
    } else if (isOccupied) {
      bgColor = colorOccupied.withOpacity(0.1);
      borderColor = colorOccupied.withOpacity(0.2);
      iconColor = colorOccupied;
    }
    return GestureDetector(
      onTap: isOccupied ? null : () => setState(() => _selectedTable = num),
      child: Container(
        width: isLarge ? 110 : 60,
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isLarge ? 15 : 25),
          boxShadow: isSelected ? [BoxShadow(color: colorSelected.withOpacity(0.3), blurRadius: 15)] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(num < 10 ? '0$num' : '$num', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary, fontSize: 16)),
              const SizedBox(height: 2),
              Container(width: 4, height: 4, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTableCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [vibrantNavy, Color(0xFF2C3E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: vibrantNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                const Text('TABLE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                Text('0$_selectedTable', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Près de la verrière', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.white70, size: 14),
                    SizedBox(width: 5),
                    Text('4 couverts', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(width: 10),
                    Text('•', style: TextStyle(color: Colors.white70)),
                    SizedBox(width: 10),
                    Text('Salle', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    bool isEnabled = _selectedTable != -1;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20), // Floating Margin
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Rounded corners
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReservationStep4())) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          disabledBackgroundColor: Colors.grey.shade200,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: isEnabled ? 5 : 0,
          shadowColor: AppColors.secondary.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isEnabled ? 'VALIDER LA RÉSERVATION' : 'SÉLECTIONNEZ UNE TABLE', style: TextStyle(color: isEnabled ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
            if (isEnabled) const SizedBox(width: 10),
            if (isEnabled) const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
