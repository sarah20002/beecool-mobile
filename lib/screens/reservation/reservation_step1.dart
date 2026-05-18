import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/bee_logo.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'reservation_step2.dart';

class ReservationStep1 extends StatefulWidget {
  const ReservationStep1({super.key});

  @override
  State<ReservationStep1> createState() => _ReservationStep1State();
}

class _ReservationStep1State extends State<ReservationStep1> {
  int _selectedEstablishment = 0;
  int _peopleCount = 4;
  int _selectedDateIndex = 2;
  String _selectedTime = "13:00";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _sectionTitle('ÉTABLISSEMENT'),
                  ),
                  const SizedBox(height: 20),
                  _buildEstablishmentList(),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _buildPeopleSelector(),
                  ),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _buildDatePicker(),
                  ),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _sectionTitle('HEURE D\'ARRIVÉE'),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _buildTimeGrid(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          _buildNextButton(),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=1000'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Dark Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Text('ÉTAPE 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text(' • /5', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('ÉTAPE 1 · OÙ & QUAND', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                const Text('Réservez\nvotre table', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, fontFamily: 'Serif', height: 1.1)),
                const SizedBox(height: 30),
                // Progress dashes
                Row(
                  children: List.generate(5, (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFFF8A11C) : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _buildEstablishmentList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          _establishmentCard(0, 'Anfa', 'Centre Ville', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=400&q=80'),
          _establishmentCard(1, 'La Marina', 'Vue Mer', 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=400&q=80'),
        ],
      ),
    );
  }

  Widget _establishmentCard(int index, String title, String sub, String img) {
    bool isSelected = _selectedEstablishment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedEstablishment = index),
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9F9F8) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? AppColors.primary.withOpacity(0.5) : Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                  child: Image.network(img, height: 110, width: double.infinity, fit: BoxFit.cover),
                ),
                if (isSelected)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFF8A11C), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleSelector() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Convives', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 17)),
                SizedBox(height: 2),
                Text('Table pour le groupe', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                _counterBtn(Icons.remove, () => setState(() => _peopleCount > 1 ? _peopleCount-- : null)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text('$_peopleCount', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                ),
                _counterBtn(Icons.add, () => setState(() => _peopleCount++), isAdd: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: isAdd ? const Color(0xFFF8A11C) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isAdd ? Colors.white : Colors.grey, size: 18),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Row(
              children: [
                const Text('Mai 2026', style: TextStyle(color: Color(0xFFF8A11C), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFF8A11C), size: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (index) {
              bool isSelected = _selectedDateIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedDateIndex = index),
                child: Container(
                  width: 55, height: 55,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'][index], style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${13 + index}', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeGrid() {
    final times = ["12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "19:00", "19:30"];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: times.map((t) {
        bool isSelected = _selectedTime == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = t),
          child: Container(
            width: (MediaQuery.of(context).size.width - 100) / 4,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF9E6E45) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? const Color(0xFF9E6E45) : Colors.transparent),
            ),
            child: Center(child: Text(t, style: TextStyle(color: isSelected ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton() {
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReservationStep2())),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Inner rounded
          elevation: 5,
          shadowColor: AppColors.secondary.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ÉTAPE SUIVANTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
