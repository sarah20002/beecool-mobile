import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../widgets/bee_logo.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _loopController;
  late AnimationController _progressController;
  late AnimationController _shineController;
  late AnimationController _wingController;

  // Orbit animations
  late Animation<double> _orbit1;
  late Animation<double> _orbit2;

  // Glow pulse animation
  late Animation<double> _glowScale;
  late Animation<double> _glowOpacity;

  // Floating animations
  late Animation<Offset> _floatA;
  late Animation<double> _rotateA;
  late Animation<Offset> _floatB;
  late Animation<double> _rotateB;
  late Animation<Offset> _floatC;
  late Animation<double> _rotateC;

  // Logo Entry
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoTranslateY;

  // Logo Bobbing
  late Animation<double> _logoBob;

  // Progress line
  late Animation<double> _progressFill;

  // Shine sweep animation
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();

    // 3.5 seconds for a slow, premium entry flight
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _wingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat();

    // 1. Logo Entry: Zoom & Fade & Translate from top of screen
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.04).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_entryController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );

    _logoTranslateY = Tween<double>(begin: -350.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    // 2. Logo Bobbing (infinite loop after entry completes)
    _logoBob = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -6.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -6.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _loopController,
        curve: const Interval(0.0, 0.5, curve: Curves.linear),
      ),
    );

    // 3. Glow Pulse (infinite loop)
    _glowScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _loopController, curve: const Interval(0.0, 0.5, curve: Curves.linear)),
    );

    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.35, end: 0.65).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 0.35).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _loopController, curve: const Interval(0.0, 0.5, curve: Curves.linear)),
    );

    // 4. Orbit Animations
    _orbit1 = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _loopController,
        curve: const Interval(0.0, 0.8125, curve: Curves.linear),
      ),
    );
    _orbit2 = Tween<double>(begin: -0.7, end: 2 * math.pi - 0.7).animate(_loopController);

    // 5. Floating Hexagons (A, B, C)
    _floatA = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween<Offset>(begin: Offset.zero, end: const Offset(8, -10)), weight: 50),
      TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(8, -10), end: Offset.zero), weight: 50),
    ]).animate(CurvedAnimation(parent: _loopController, curve: const Interval(0.0, 0.875, curve: Curves.easeInOut)));
    _rotateA = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.1, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _loopController, curve: const Interval(0.0, 0.875, curve: Curves.easeInOut)));

    _floatB = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween<Offset>(begin: Offset.zero, end: const Offset(-12, 8)), weight: 50),
      TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(-12, 8), end: Offset.zero), weight: 50),
    ]).animate(_loopController); 
    _rotateB = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -0.08), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -0.08, end: 0.0), weight: 50),
    ]).animate(_loopController);

    _floatC = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween<Offset>(begin: Offset.zero, end: const Offset(6, 12)), weight: 50),
      TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(6, 12), end: Offset.zero), weight: 50),
    ]).animate(CurvedAnimation(parent: _loopController, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)));
    _rotateC = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.07), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.07, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _loopController, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)));

    // 6. Progress Fill
    _progressFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // 7. Shine Sweep Animation
    _shineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shineController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Start entry animations
    _entryController.forward().then((_) {
      if (mounted) {
        _loopController.repeat();
        _wingController.duration = const Duration(milliseconds: 600); // slow hover flapping
        _wingController.repeat();
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _progressController.forward();
    });

    _navigateToOnboarding();
  }

  _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 7), () {});
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _loopController.dispose();
    _progressController.dispose();
    _shineController.dispose();
    _wingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1726),
      body: Stack(
        children: [
          // Background Hexagon A (Floating A)
          AnimatedBuilder(
            animation: Listenable.merge([_floatA, _rotateA]),
            builder: (context, child) {
              return Positioned(
                top: -40 + _floatA.value.dy, 
                right: -40 + _floatA.value.dx, 
                child: Transform.rotate(
                  angle: 0.5 + _rotateA.value,
                  child: _buildHexagon(180, const Color(0xFF132238)),
                ),
              );
            },
          ),
          
          // Background Hexagon B (Floating B)
          AnimatedBuilder(
            animation: Listenable.merge([_floatB, _rotateB]),
            builder: (context, child) {
              return Positioned(
                top: 320 + _floatB.value.dy, 
                left: -50 + _floatB.value.dx, 
                child: Transform.rotate(
                  angle: 0.5 + _rotateB.value,
                  child: _buildHexagon(140, const Color(0xFF132238)),
                ),
              );
            },
          ),

          // Background Hexagon C (Floating C)
          AnimatedBuilder(
            animation: Listenable.merge([_floatC, _rotateC]),
            builder: (context, child) {
              return Positioned(
                bottom: 220 + _floatC.value.dy, 
                left: 30 + _floatC.value.dx, 
                child: Transform.rotate(
                  angle: 0.5 + _rotateC.value,
                  child: _buildHexagon(80, const Color(0xFF132238)),
                ),
              );
            },
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo wrapper with glow + orbiting hex
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Luminous flight path trail of the bee
                      AnimatedBuilder(
                        animation: Listenable.merge([_entryController]),
                        builder: (context, child) {
                          final double fadeOpacity = (1.0 - _entryController.value).clamp(0.0, 1.0);
                          if (fadeOpacity <= 0) return const SizedBox.shrink();

                          return CustomPaint(
                            size: const Size(200, 200),
                            painter: FlightPathPainter(
                              progress: _entryController.value,
                              fadeOpacity: fadeOpacity,
                            ),
                          );
                        },
                      ),

                      // Pulsing honey glow
                      AnimatedBuilder(
                        animation: Listenable.merge([_glowScale, _glowOpacity]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _glowScale.value,
                            child: Opacity(
                              opacity: _glowOpacity.value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFFC9910).withOpacity(0.45),
                                      const Color(0xFFFC9910).withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.65],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Orbiting hexagon 1
                      AnimatedBuilder(
                        animation: _orbit1,
                        builder: (context, child) {
                          final angle = _orbit1.value;
                          return Transform.translate(
                            offset: Offset(80 * math.cos(angle), 80 * math.sin(angle)),
                            child: Transform.rotate(
                              angle: 0.5,
                              child: _buildHexagon(14, const Color(0xFFFC9910)),
                            ),
                          );
                        },
                      ),
                      
                      // Orbiting hexagon 2
                      AnimatedBuilder(
                        animation: _orbit2,
                        builder: (context, child) {
                          final angle = _orbit2.value;
                          return Transform.translate(
                            offset: Offset(80 * math.cos(angle), 80 * math.sin(angle)),
                            child: Opacity(
                              opacity: 0.7,
                              child: Transform.rotate(
                                angle: 0.5,
                                child: _buildHexagon(10, const Color(0xFFFC9910)),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Logo Illustration (Bobbing, entry translation, wing flap and scaling)
                      AnimatedBuilder(
                        animation: Listenable.merge([_logoScale, _logoOpacity, _logoTranslateY, _logoBob, _wingController, _entryController]),
                        builder: (context, child) {
                          final double progress = _entryController.value;
                          
                          // Organic horizontal deviations (Sine-wave oscillation with damping as it settles)
                          final double deviationX = _entryController.isCompleted 
                              ? 0.0 
                              : 30.0 * math.sin(progress * 3.5 * math.pi) * (1.0 - progress);

                          return Transform.translate(
                            offset: Offset(deviationX, _logoTranslateY.value + _logoBob.value),
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Opacity(
                                opacity: _logoOpacity.value,
                                child: BeeIllustration(
                                  height: 100,
                                  wingFlap: _wingController.value,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: AnimatedBuilder(
                    animation: _shineAnimation,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          final value = _shineAnimation.value;
                          final double slide = -bounds.width + (value * bounds.width * 2.5);
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFD54F).withOpacity(0.4),
                              Colors.white,
                              Colors.white,
                              const Color(0xFFFFD54F).withOpacity(0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.35, 0.46, 0.49, 0.51, 0.54, 0.65],
                          ).createShader(
                            Rect.fromLTWH(
                              bounds.left + slide,
                              bounds.top,
                              bounds.width,
                              bounds.height,
                            ),
                          );
                        },
                        blendMode: BlendMode.srcATop,
                        child: const BeeTextLogo(fontSize: 48, color: Colors.white),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 14),
                const Text(
                  'RESTAURANT · مطعم',
                  style: TextStyle(color: AppColors.secondary, fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 25),
                FadeIn(
                  delay: const Duration(milliseconds: 700),
                  child: const Text(
                    '« L\'art de la table, le goût de l\'instant. »',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Serif',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom progress
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _progressFill,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 3,
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progressFill.value,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.secondary, 
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'CHARGEMENT',
                  style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexagon(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        border: Border.all(color: color.withOpacity(0.8), width: 1.5),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
    );
  }
}

class FlightPathPainter extends CustomPainter {
  final double progress;
  final double fadeOpacity;

  FlightPathPainter({required this.progress, required this.fadeOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || fadeOpacity <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFFFC9910).withOpacity(fadeOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final glowPaint = Paint()
      ..color = const Color(0xFFFC9910).withOpacity(fadeOpacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final path = Path();
    
    // Starting point at top of flight path (Y = -350 + 100 = -250 relative to 200x200 center)
    const double startY = -350.0 + 100.0;
    path.moveTo(100.0, startY);

    final int steps = (progress * 80).toInt().clamp(5, 80);
    for (int i = 1; i <= steps; i++) {
      final double p = (progress * i) / steps;
      final double y = -350.0 + 350.0 * Curves.easeOutCubic.transform(p) + 100.0;
      final double x = 100.0 + 30.0 * math.sin(p * 3.5 * math.pi) * (1.0 - p);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FlightPathPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.fadeOpacity != fadeOpacity;
  }
}
