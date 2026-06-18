import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../home/home_screen.dart';
import '../../core/utils/notification_helper.dart';

class ReviewScreen extends StatefulWidget {
  final String? orderId;
  final String? sessionToken;

  const ReviewScreen({super.key, this.orderId, this.sessionToken});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final List<String> _tags = ['Service', 'Ambiance', 'Plats', 'Rapidité', 'Propreté'];
  final List<String> _selectedTags = ['Service', 'Plats'];
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _alreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadySubmitted();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadySubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    final token = widget.sessionToken;
    if (token != null && token.isNotEmpty) {
      final submitted = prefs.getBool('feedback_submitted_$token') ?? false;
      if (submitted) {
        final savedRating = prefs.getInt('feedback_rating_$token') ?? 5;
        final savedComment = prefs.getString('feedback_comment_$token') ?? '';
        setState(() {
          _alreadySubmitted = true;
          _rating = savedRating;
          _commentController.text = savedComment;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    final token = widget.sessionToken;
    final orderId = widget.orderId;

    if (orderId == null || orderId.isEmpty) {
      // Fallback in case of null values
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Nous envoyons toujours le feedback au serveur (qu'il soit nouveau ou un ajustement)

      // First time submit - call backend
      final jwtToken = await AuthService().getToken();
      debugPrint('Envoi du feedback au serveur. Token JWT: $jwtToken');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Platform': 'mobile',
          if (jwtToken != null && jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
        },
      ));

      final feedbackData = {
        'commandeId': orderId,
        'nbreEtoiles': _rating,
        'message': _commentController.text.isNotEmpty ? _commentController.text : 'Très bon service !',
      };

      final response = await dio.post('/feedbacks', data: feedbackData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (token != null && token.isNotEmpty) {
          await prefs.setBool('feedback_submitted_$token', true);
          await prefs.setInt('feedback_rating_$token', _rating);
          await prefs.setString('feedback_comment_$token', _commentController.text);
        }

        if (mounted) {
          NotificationHelper.showSuccess(
            context, 
            title: "Avis enregistré", 
            message: _alreadySubmitted 
                ? 'Votre avis a été ajusté avec succès pour cette session !'
                : 'Merci pour votre avis ! Votre feedback a été enregistré avec succès.'
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      String msg = 'Erreur lors de la soumission de votre avis.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          msg = data['message']?.toString() ?? msg;
        } else if (data is String) {
          msg = data;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      if (msg.contains('déjà laissé un avis')) {
        if (token != null && token.isNotEmpty) {
          await prefs.setBool('feedback_submitted_$token', true);
        }
      }
      
      if (mounted) {
        NotificationHelper.showError(
          context, 
          title: "Erreur de soumission", 
          message: msg,
          onRetry: () => _submitFeedback()
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: Stack(
        children: [
          // ─── Content ───
          SingleChildScrollView(
            child: Column(
              children: [
                _buildFullWidthHeader(),
                
                // ─── Review Form Box ───
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 40),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 25),
                      _buildStarRating(),
                      const SizedBox(height: 35),
                      _buildFeedbackField(),
                      const SizedBox(height: 35),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // BottomNav spacing
              ],
            ),
          ),

          // ─── Glass Back Button ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _GlassButton(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: -1),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFullWidthHeader() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1000'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.3), Colors.transparent, const Color(0xFFF9F9F8)],
          ),
        ),
        padding: const EdgeInsets.all(30),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VOTRE COMMANDE DE TABLE', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            SizedBox(height: 8),
            Text('Beecool Restaurant', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontFamily: 'Serif'),
            children: [
              TextSpan(text: _alreadySubmitted ? 'Ajuster votre ' : 'Merci de votre '),
              TextSpan(
                text: _alreadySubmitted ? 'avis !' : 'visite !', 
                style: const TextStyle(color: Color(0xFFF8A11C), fontStyle: FontStyle.italic)
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _alreadySubmitted 
            ? 'Vous avez déjà laissé un avis pour cette session de table. Souhaitez-vous ajuster vos notes ou vos commentaires ?'
            : 'Votre opinion compte énormément pour nous. Comment s\'est passée votre expérience aujourd\'hui ?',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        bool isFilled = index < _rating;
        return GestureDetector(
          onTap: () => setState(() => _rating = index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFilled ? const Color(0xFFF8A11C) : Colors.grey.shade200,
              size: 40,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dites-nous en plus (optionnel)', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          height: 140,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Qu\'avez-vous particulièrement apprécié ?',
              hintStyle: TextStyle(color: Colors.black12, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: _tags.map((tag) => _buildTag(tag)).toList(),
    );
  }

  Widget _buildTag(String label) {
    bool isSelected = _selectedTags.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) _selectedTags.remove(label);
          else _selectedTags.add(label);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8A11C).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFFF8A11C) : Colors.grey.shade100, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? const Color(0xFFF8A11C) : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitFeedback,
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF8A11C), Color(0xFFDC861A)]),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF8A11C).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Center(
          child: _isLoading 
            ? const CircularProgressIndicator(color: Color(0xFF0F172A))
            : Text(
                _alreadySubmitted ? 'Ajuster mon avis' : 'Envoyer mon avis',
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
              ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final Widget child; final VoidCallback? onTap;
  const _GlassButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
