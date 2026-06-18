import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'reservation_step3.dart';

class ReservationStep2 extends StatefulWidget {
  final Map<String, dynamic> etablissement;
  final DateTime date;
  final String heure;
  final int nbPersonnes;

  const ReservationStep2({
    super.key,
    required this.etablissement,
    required this.date,
    required this.heure,
    required this.nbPersonnes,
  });

  @override
  State<ReservationStep2> createState() => _ReservationStep2State();
}

class _ReservationStep2State extends State<ReservationStep2> {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;
  bool _isLoginModeForGuest = false; // toggle for guest signup vs login
  bool _isSubmitting = false;

  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _demandeSpecialeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _demandeSpecialeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final profile = await AuthService().getProfile();
      if (profile != null && mounted) {
        setState(() {
          _isAuthenticated = true;
          _prenomController.text = profile['prenom'] ?? '';
          _nomController.text = profile['nom'] ?? '';
          _phoneController.text = (profile['telephone'] ?? '').toString().replaceAll('+216', '');
          _emailController.text = profile['email'] ?? '';
          _isCheckingAuth = false;
        });
      } else if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> _handleNextStep() async {
    if (_isSubmitting) return;

    // Si déjà connecté, passer direct à l'étape 3
    if (_isAuthenticated) {
      _goToStep3();
      return;
    }

    // Validation des champs
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError("Erreur", "Veuillez remplir les champs obligatoires (email et mot de passe).");
      return;
    }

    if (!_isLoginModeForGuest) {
      if (_prenomController.text.trim().isEmpty ||
          _nomController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        _showError("Erreur", "Veuillez remplir tous les champs d'inscription.");
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isLoginModeForGuest) {
        // Mode Connexion
        final data = await AuthService().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (data != null) {
          _showSuccess("Connecté !", "Bienvenue à nouveau !");
          _goToStep3();
        } else {
          _showError("Échec", "Identifiants incorrects.");
        }
      } else {
        // Mode Inscription
        final String fullPhone = '+216${_phoneController.text.trim().replaceAll(' ', '')}';
        final success = await AuthService().register(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          telephone: fullPhone,
        );

        if (success) {
          _showSuccess("Compte créé !", "Votre compte a été enregistré avec succès.");
          _goToStep3();
        } else {
          _showError("Erreur", "Une erreur est survenue lors de la création du compte.");
        }
      }
    } catch (e) {
      _showError("Erreur", e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _goToStep3() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationStep3(
          etablissement: widget.etablissement,
          date: widget.date,
          heure: widget.heure,
          nbPersonnes: widget.nbPersonnes,
          nomReservation: '${_prenomController.text.trim()} ${_nomController.text.trim()}',
          telephone: '+216${_phoneController.text.trim().replaceAll(' ', '')}',
          email: _emailController.text.trim(),
          demandeSpeciale: _demandeSpecialeController.text.trim(),
        ),
      ),
    );
  }

  void _showError(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title: $message"),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title: $message"),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String heroImg = (widget.etablissement['image'] != null && widget.etablissement['image'].toString().startsWith('http'))
        ? widget.etablissement['image']
        : 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&q=80&w=1000';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeroHeader(context, heroImg),
          Expanded(
            child: _isCheckingAuth
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    child: Column(
                      children: [
                        Container(
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
                          if (!_isAuthenticated) ...[
                            _buildModeSelector(),
                            const SizedBox(height: 25),
                          ],
                          
                          _sectionHeader('IDENTITÉ'),
                          const SizedBox(height: 15),
                          
                          if (!_isAuthenticated && _isLoginModeForGuest) ...[
                            // Mode Connexion simple
                            _buildTextField('Email', 'votre.email@gmail.com', _emailController, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 20),
                            _buildTextField('Mot de passe', '••••••••', _passwordController, obscureText: true),
                          ] else ...[
                            // Mode inscription (Invité) ou Profil déjà connecté
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Prénom', 'Yasmine', _prenomController, enabled: !_isAuthenticated)),
                                const SizedBox(width: 15),
                                Expanded(child: _buildTextField('Nom', 'Bennis', _nomController, enabled: !_isAuthenticated)),
                              ],
                            ),
                            const SizedBox(height: 25),
                            _sectionHeader('CONTACT'),
                            const SizedBox(height: 15),
                            _buildPhoneField(enabled: !_isAuthenticated),
                            const SizedBox(height: 20),
                            _buildTextField('Email', 'yasmine.b@gmail.com', _emailController, keyboardType: TextInputType.emailAddress, enabled: !_isAuthenticated),
                            
                            if (!_isAuthenticated) ...[
                              const SizedBox(height: 20),
                              _buildTextField('Créer un mot de passe', '••••••••', _passwordController, obscureText: true),
                            ],
                          ],
                          
                          const SizedBox(height: 30),
                          _sectionHeader('DEMANDE SPÉCIALE'),
                          const SizedBox(height: 15),
                          _buildTextField('', 'Ex: possibilité d\'avoir une table près de la fenêtre ?', _demandeSpecialeController, maxLines: 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isCheckingAuth) _buildNextButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String bgImage) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(bgImage),
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
                  Colors.black.withOpacity(0.6),
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
                          Text(' • /4', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('ÉTAPE 2 · COORDONNÉES', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                const Text('Vos\ncoordonnées', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, fontFamily: 'Serif', height: 1.1)),
                const SizedBox(height: 25),
                Row(
                  children: List.generate(4, (index) => Expanded(
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

  Widget _buildModeSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginModeForGuest = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isLoginModeForGuest ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isLoginModeForGuest ? [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Créer un compte",
                  style: TextStyle(
                    color: !_isLoginModeForGuest ? const Color(0xFF0A1128) : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginModeForGuest = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isLoginModeForGuest ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isLoginModeForGuest ? [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  "J'ai déjà un compte",
                  style: TextStyle(
                    color: _isLoginModeForGuest ? const Color(0xFF0A1128) : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _buildTextField(
    String label, 
    String hint, 
    TextEditingController controller, {
    int maxLines = 1, 
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
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
            color: enabled ? const Color(0xFFF9F9F8) : const Color(0xFFE2E8F0).withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines > 1 ? 1 : null,
            obscureText: obscureText,
            keyboardType: keyboardType,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B), 
              fontSize: 14, 
              fontWeight: FontWeight.bold
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField({bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Téléphone', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF9F9F8) : const Color(0xFFE2E8F0).withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFDEFD9), borderRadius: BorderRadius.circular(12)),
                child: const Text('TN +216', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: enabled,
                  style: TextStyle(
                    color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B), 
                    fontSize: 15, 
                    fontWeight: FontWeight.bold
                  ),
                  decoration: InputDecoration(
                    hintText: '55 123 456',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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

  Widget _buildNextButton() {
    String btnText = 'ÉTAPE SUIVANTE';
    if (!_isAuthenticated) {
      btnText = _isLoginModeForGuest ? 'SE CONNECTER & CONTINUER' : 'CRÉER MON COMPTE & CONTINUER';
    }

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
        onPressed: _isSubmitting ? null : _handleNextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          shadowColor: AppColors.secondary.withOpacity(0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(btnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}
