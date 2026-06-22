import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../menu/menu_screen.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/notification_helper.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  late AnimationController _animationController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processTableId(String input) async {
    if (_isProcessing) return;
    
    String tableId = input.trim();
    // Extraire l'ID si l'utilisateur a collé l'URL complète
    if (tableId.contains('/scan/')) {
      tableId = tableId.split('/scan/').last;
    } else if (tableId.contains('/')) {
      tableId = tableId.split('/').last;
    }

    setState(() {
      _isProcessing = true;
    });
    _scannerController.stop();

    final prefs = await SharedPreferences.getInstance();
    final token = await AuthService().getToken();

    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'X-Platform': 'mobile',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ));

    try {
      final response = await dio.get('/tables/$tableId/scan');
      if (response.statusCode == 200) {
        final data = response.data;
        final etablissementId = data['etablissementId'];
        final sessionToken = data['sessionToken'];

        if (context.mounted && etablissementId != null && etablissementId.toString().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final userEmail = prefs.getString('user_email');
          final isRealClient = userEmail != null && userEmail.isNotEmpty;

          CartService().setEtablissementId(etablissementId.toString());
          if (sessionToken != null) {
            CartService().setSessionToken(sessionToken.toString());
          }
          final token = data['token'];
          if (token != null) {
            await AuthService().saveToken(token.toString());
          }

          // Security: clear the manual input field so it doesn't stay visible
          _idController.clear();

          if (!isRealClient) {
            // Guest/Invite -> Link the name entered during guest mode selection to the backend table session!
            final guestName = prefs.getString('user_prenom') ?? 'Invite';
            final guestDio = Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              headers: {
                'Content-Type': 'application/json',
                'X-Platform': 'mobile',
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ));
            try {
              final inviteResponse = await guestDio.post('/tables/session/token/$sessionToken/invite?nom=$guestName');
              if (inviteResponse.statusCode == 200 || inviteResponse.statusCode == 201) {
                final inviteData = inviteResponse.data;
                if (inviteData != null && inviteData['id'] != null) {
                  final guestId = inviteData['id'].toString();
                  await prefs.setString('guest_id', guestId);
                  debugPrint('Successfully registered guest with ID: $guestId');
                }
              }
            } catch (inviteErr) {
              debugPrint('Error linking scanned guest name to session: $inviteErr');
            }
          }

          if (context.mounted) {
            NotificationHelper.showSuccess(
              context,
              title: 'Table Connectée !',
              message: 'Bienvenue. Vous pouvez maintenant consulter le menu et passer commande.',
            );
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                etablissementId: etablissementId.toString(),
                sessionToken: sessionToken?.toString(),
              ),
            ),
          );
          return; // Success
        }
      }
    } catch (e) {
      String errorMessage = 'Table introuvable ou erreur réseau.';
      if (e is DioException && e.response?.data != null) {
        // Extraire le message d'erreur envoyé par le GlobalExceptionHandler du backend
        final resData = e.response?.data;
        if (resData is Map) {
          errorMessage = resData['message'] ?? errorMessage;
        } else if (resData is String) {
          errorMessage = resData;
        }
      }
      
      if (context.mounted) {
        NotificationHelper.showWarning(
          context,
          title: 'Erreur',
          message: errorMessage,
        );
      }
    }
    
    // Resume scanner if failed
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
            ),
          ),
        ),
        title: const Text(
          'Scanner',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    FadeInDown(
                      child: Column(
                        children: [
                          const Text(
                            'TABLE CONNECTÉE',
                            style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(fontSize: 28, color: AppColors.primary, fontFamily: 'Serif'),
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
                    
                    // Scanner Box
                    FadeIn(
                      delay: const Duration(milliseconds: 500),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withOpacity(0.4), // Bleu avec transparence (Glassmorphism)
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: MobileScanner(
                                  controller: _scannerController,
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes = capture.barcodes;
                                    for (final barcode in barcodes) {
                                      if (barcode.rawValue != null) {
                                        _processTableId(barcode.rawValue!);
                                        break;
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            // Watermark icon in the center
                            IgnorePointer(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85), // Slightly transparent white
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.qr_code_2_rounded, color: Color(0xFF1E3A8A), size: 100),
                                ),
                              ),
                            ),
                            _buildCorners(),
                            // Animated Scanner Line
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Positioned(
                                  top: 20 + (_animationController.value * 240), // Animates up and down within the 280x280 box
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFFC9910).withOpacity(0.0),
                                          const Color(0xFFFC9910),
                                          const Color(0xFFFC9910).withOpacity(0.0),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFFFC9910).withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Accédez à la carte, commandez et payez sans quitter votre table.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300, indent: 40, endIndent: 10)),
                        Text('OU', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                        Expanded(child: Divider(color: Colors.grey.shade300, indent: 10, endIndent: 40)),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Manual Input Field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SAISIR L\'IDENTIFIANT',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8), // Goutte d'eau effect
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _idController,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'Ex. TABLE-07',
                                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
                                      prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB), size: 22), // Bleu clair/marine (pas noir)
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              GestureDetector(
                                onTap: () {
                                  if (_idController.text.isNotEmpty) {
                                    _processTableId(_idController.text);
                                  }
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8A11C), // Jaune/Orange lumineux comme sur l'image
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF8A11C).withOpacity(0.6), // Trace à l'entour (Glow)
                                        blurRadius: 18,
                                        spreadRadius: 3,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCorners() {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        children: [
          _corner(Alignment.topLeft, const BorderRadius.only(topLeft: Radius.circular(30))),
          _corner(Alignment.topRight, const BorderRadius.only(topRight: Radius.circular(30))),
          _corner(Alignment.bottomLeft, const BorderRadius.only(bottomLeft: Radius.circular(30))),
          _corner(Alignment.bottomRight, const BorderRadius.only(bottomRight: Radius.circular(30))),
        ],
      ),
    );
  }

  Widget _corner(Alignment alignment, BorderRadius radius) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          ),
          borderRadius: radius,
        ),
      ),
    );
  }

}
