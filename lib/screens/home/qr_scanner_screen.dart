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

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TextEditingController _idController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture de la table en cours...'), duration: Duration(seconds: 1)),
    );

    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scanner',
          style: TextStyle(color: AppColors.primary, fontFamily: 'Serif', fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined, color: AppColors.primary, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
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
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
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
                  _buildCorners(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ou saisissez manuellement l\'identifiant de la table',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
          ),
          
          const Spacer(),
          
          // Manual Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'ID de la table',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: AppColors.secondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (_idController.text.isNotEmpty) {
                      _processTableId(_idController.text);
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
