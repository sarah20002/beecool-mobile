import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/bee_logo.dart';
import '../../core/services/auth_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/notification_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'sarra@beecool.com');
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      NotificationHelper.showWarning(
        context, 
        title: "Champs requis", 
        message: "Veuillez remplir tous les champs."
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context, 
          title: "Échec de connexion", 
          message: "Identifiants incorrects ou problème réseau.",
          onRetry: () => _handleLogin()
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image with Rounded Bottom
          _buildBackgroundHeader(),
          
          // Form Section
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 250), // Overlap starts here
                _buildFloatingLoginForm(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundHeader() {
    return Container(
      height: 320, // Reduced height
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60), // VERY ROUNDED BOTTOM
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
              Colors.black.withOpacity(0.3),
              AppColors.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: [
                    FadeInLeft(
                      child: const Row(
                        children: [
                          BeeIllustration(height: 35),
                          SizedBox(width: 8),
                          BeeTextLogo(fontSize: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              FadeInDown(
                child: const Text(
                  'Heureux de vous revoir',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                ),
              ),
              const SizedBox(height: 5),
              FadeInUp(
                child: const Text(
                  'CONNEXION',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingLoginForm() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(25, 40, 25, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField('EMAIL', 'sarra@beecool.com', controller: _emailController),
            const SizedBox(height: 25),
            _buildInputField(
              'MOT DE PASSE', 
              '••••••••••••', 
              controller: _passwordController,
              isPassword: true,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v!),
                        activeColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Se souvenir', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 35),
            _buildConnectButton(),
            const SizedBox(height: 30),
            _buildSeparator(),
            const SizedBox(height: 25),
            _buildGuestButton(),
            const SizedBox(height: 25),
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.5), width: 1.5),
      ),
      child: OutlinedButton.icon(
        onPressed: () => _showGuestNameInputModal(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: const Icon(Icons.person_outline_rounded, color: AppColors.secondary, size: 20),
        label: const Text(
          "Continuer en tant qu'invité", 
          style: TextStyle(color: AppColors.secondary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showGuestNameInputModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: AppColors.secondary, size: 24),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONNEXION INVITÉ',
                              style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            Text(
                              'Entrez votre prénom',
                              style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Saisissez votre prénom ou le nom de votre groupe afin de personnaliser votre expérience sur la table.',
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre prénom';
                        }
                        if (value.trim().length < 2) {
                          return 'Le prénom doit contenir au moins 2 caractères';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Ex: Sarra, Table 4, Invité...',
                        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () async {
                      if (formKey.currentState!.validate()) {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        try {
                          await _authService.logout();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('user_prenom', nameController.text.trim());
                          // On supprime l'email utilisateur pour s'assurer que c'est bien considéré comme un invité
                          await prefs.remove('user_email');
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error registering guest name: $e');
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      }
                    },
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.secondary, Color(0xFFDC861A)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirmer',
                              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(String label, String hint, {required TextEditingController controller, bool isPassword = false, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100, width: 2),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Se connecter', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text('OU', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Nouveau chez BeeCool ? ", style: TextStyle(color: Colors.grey, fontSize: 13)),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
          child: const Text("Créer un compte", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}
