import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import 'reservation_step3.dart';

class ReservationStep2 extends StatefulWidget {
  const ReservationStep2({super.key});

  @override
  State<ReservationStep2> createState() => _ReservationStep2State();
}

class _ReservationStep2State extends State<ReservationStep2> {
  bool _isSpecialOccasion = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('IDENTITÉ'),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Prénom', 'Yasmine')),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTextField('Nom', 'Bennis')),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _sectionHeader('CONTACT'),
                    const SizedBox(height: 15),
                    _buildPhoneField(),
                    const SizedBox(height: 20),
                    _buildTextField('Email', 'yasmine.b@gmail.com'),
                    const SizedBox(height: 30),
                    _sectionHeader('DEMANDE SPÉCIALE'),
                    const SizedBox(height: 15),
                    _buildTextField('', 'Anniversaire de mariage — possibilité d\'avoir une table près de la fenêtre ?', maxLines: 3),
                    const SizedBox(height: 30),
                    _buildSpecialOccasionSwitch(),
                  ],
                ),
              ),
            ),
          ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&q=80&w=1000'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
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
                          Text('ÉTAPE 2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text(' • /5', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('ÉTAPE 2 · CONTACT', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                const Text('Vos\ncoordonnées', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, fontFamily: 'Serif', height: 1.1)),
                const SizedBox(height: 30),
                Row(
                  children: List.generate(5, (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: index <= 1 ? const Color(0xFFF8A11C) : Colors.white.withOpacity(0.2),
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

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: TextField(
            maxLines: maxLines,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Téléphone', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFDEFD9), borderRadius: BorderRadius.circular(12)),
                child: const Text('TN +216', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: TextField(
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '6 12 34 56 78',
                    hintStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialOccasionSwitch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFFDEFD9), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Occasion spéciale', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16, fontFamily: 'Serif')),
                Text('Anniversaire · Chef informé', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: _isSpecialOccasion,
            onChanged: (v) => setState(() => _isSpecialOccasion = v),
            activeColor: AppColors.secondary,
            activeTrackColor: AppColors.secondary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReservationStep3())),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          shadowColor: AppColors.secondary.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CHOISIR UNE TABLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
