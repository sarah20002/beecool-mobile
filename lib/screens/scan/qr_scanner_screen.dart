import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scanner',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_iridescent_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          // Title Section
          FadeInDown(
            child: Column(
              children: [
                const Text(
                  'TABLE CONNECTÉE',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 28, fontFamily: 'Serif', color: AppColors.primary, height: 1.2),
                    children: [
                      TextSpan(text: 'Cadrez le QR \n'),
                      TextSpan(text: 'de votre table', style: TextStyle(color: AppColors.secondary, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Scanner Area
          Center(
            child: FadeIn(
              duration: const Duration(seconds: 1),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Stack(
                  children: [
                    // QR Code Image Placeholder
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                            image: NetworkImage('https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=BeeCoolTable12'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    
                    // Orange Corners
                    _buildCorner(top: 20, left: 20, rotate: 0),
                    _buildCorner(top: 20, right: 20, rotate: 1),
                    _buildCorner(bottom: 20, left: 20, rotate: 3),
                    _buildCorner(bottom: 20, right: 20, rotate: 2),
                    
                    // Detection Text
                    Positioned(
                      bottom: 20,
                      width: 300,
                      child: Center(
                        child: Text(
                          'DÉTECTION EN COURS...',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Bottom Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40),
            child: Text(
              'Accédez à la carte, commandez et payez sans bouger.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, required int rotate}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotate * 1.5708, // 90 degrees in radians
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.secondary, width: 4),
              left: BorderSide(color: AppColors.secondary, width: 4),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}
