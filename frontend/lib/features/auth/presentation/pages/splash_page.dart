import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gold_particle_painter.dart';
import '../../../../core/widgets/shimmer_text.dart';

/// Splash Screen — écran d'accueil luxueux avec particules dorées
/// Séquence : fond noir → particules → logo → texte → barre → navigation
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  // Contrôleurs d'animation
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _barController;
  late final AnimationController _fadeOutController;

  // Animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _barProgress;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo : scale + fade (500ms → 800ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Texte "STUDIO PHOTO" : slide up + fade (800ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Barre de chargement (1200ms → 2800ms)
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );

    // Fade out final
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );
  }

  void _startSequence() async {
    // 200ms : début (particules commencent automatiquement)
    await Future.delayed(const Duration(milliseconds: 500));

    // 500ms : logo fade in + scale elasticOut
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // 800ms : texte slide up + fade
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // 1200ms : barre de chargement
    _barController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    // 3000ms : fade out puis navigation
    _fadeOutController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _barController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _fadeOut,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: child,
          );
        },
        child: Stack(
          children: [
            // Arrière-plan : particules dorées
            const Positioned.fill(
              child: AnimatedGoldParticles(particleCount: 40),
            ),

            // Contenu centré
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo avec scale + fade
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 56,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Texte "STUDIO PHOTO" avec shimmer + slide
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: SlideTransition(
                          position: _textSlide,
                          child: child,
                        ),
                      );
                    },
                    child: ShimmerText(
                      text: 'STUDIO PHOTO',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sous-titre
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: child,
                      );
                    },
                    child: Text(
                      'Gestion professionnelle',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Barre de chargement dorée en bas
            Positioned(
              left: 60,
              right: 60,
              bottom: 80,
              child: AnimatedBuilder(
                animation: _barProgress,
                builder: (context, _) {
                  return Column(
                    children: [
                      // Barre
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: AppColors.surface,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _barProgress.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: AppColors.goldGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
