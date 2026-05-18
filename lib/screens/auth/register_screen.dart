import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/bee_logo.dart';
import '../../core/services/auth_service.dart';
import 'login_screen.dart';
import '../../core/utils/notification_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _acceptTerms = true;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_acceptTerms) {
      NotificationHelper.showWarning(
        context, 
        title: "Conditions requises", 
        message: "Veuillez accepter les conditions d'utilisation."
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.register(
        nom: _lastNameController.text.trim(),
        prenom: _firstNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        telephone: _phoneController.text.trim(),
      );

      if (success && mounted) {
        NotificationHelper.showSuccess(
          context, 
          title: "Compte créé !", 
          message: "Votre compte a été créé avec succès. Connectez-vous !"
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context, 
          title: "Échec d'inscription", 
          message: "Veuillez vérifier vos informations et réessayer.",
          onRetry: () => _handleRegister()
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFA),
      body: Stack(
        children: [
          // Background Image with Rounded Bottom (Like Login)
          _buildBackgroundHeader(context),
          
          // Floating Scrollable Form
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 230), // Overlap area
                _buildFloatingRegisterForm(),
                const SizedBox(height: 30),
                _buildLoginLink(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundHeader(BuildContext context) {
    return Container(
      height: 320, // Same as Login
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60), // ROUNDED BOTTOM
          bottomRight: Radius.circular(60),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(60),
            bottomRight: Radius.circular(60),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.1),
              AppColors.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BeeIllustration(height: 30),
                  SizedBox(width: 8),
                  BeeTextLogo(fontSize: 16, color: Colors.white),
                ],
              ),
              const SizedBox(height: 15),
              const Text('INSCRIPTION', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 8),
              const Text(
                'Rejoignez la ruche',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingRegisterForm() {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25), // DETACHED FROM SIDES
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40), // FULLY ROUNDED
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _socialBtn(Icons.apple),
                _socialBtn(Icons.g_mobiledata, color: Colors.red),
                _socialBtn(Icons.facebook, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 25),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('OU PAR EMAIL', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: _buildInputField(Icons.person_outline, 'Yasmine', controller: _firstNameController)),
                const SizedBox(width: 15),
                Expanded(child: _buildInputField(null, 'Bennis', controller: _lastNameController)),
              ],
            ),
            const SizedBox(height: 15),
            _buildInputField(Icons.email_outlined, 'yasmine.b@gmail.com', controller: _emailController),
            const SizedBox(height: 15),
            _buildInputField(Icons.phone_outlined, '+212 6 12 34 56 78', controller: _phoneController),
            const SizedBox(height: 15),
            _buildPasswordField(),
            const SizedBox(height: 20),
            _buildTermsRow(),
            const SizedBox(height: 30),
            _buildActionBtn(),
          ],
        ),
      ),
    );
  }

  Widget _socialBtn(IconData icon, {Color color = AppColors.primary}) {
    return Container(
      width: 75, height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildInputField(IconData? icon, String hint, {required TextEditingController controller}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          icon: icon != null ? Icon(icon, color: Colors.grey, size: 18) : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.secondary.withOpacity(0.5), width: 1.5),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              icon: const Icon(Icons.lock_outline, color: AppColors.secondary, size: 18),
              hintText: '••••••••••••',
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _strengthBar(AppColors.secondary),
            _strengthBar(AppColors.secondary),
            _strengthBar(Colors.green),
            _strengthBar(Colors.grey.shade200),
          ],
        ),
        const SizedBox(height: 5),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Force : solide', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('8+ caractères ✓', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _strengthBar(Color color) {
    return Expanded(
      child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      children: [
        SizedBox(
          width: 24, height: 24,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v!),
            activeColor: AppColors.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: "J'accepte les ",
              style: TextStyle(color: Colors.grey, fontSize: 11),
              children: [
                TextSpan(text: 'Conditions', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                TextSpan(text: ' et la '),
                TextSpan(text: 'Politique', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.secondary, Color(0xFFD48400)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CRÉER MON COMPTE', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(width: 15),
                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Déjà inscrit-e ? ", style: TextStyle(color: Colors.grey, fontSize: 13)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text("Connectez-vous", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
        ),
      ],
    );
  }
}

