import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Particule dorée individuelle
class _GoldParticle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;

  _GoldParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

/// Particules dorées montant lentement depuis le bas avec fade out
class GoldParticlePainter extends CustomPainter {
  final double animationValue;
  final List<_GoldParticle> _particles;

  GoldParticlePainter._({
    required this.animationValue,
    required List<_GoldParticle> particles,
  }) : _particles = particles;

  /// Crée un GoldParticlePainter avec particules aléatoires
  factory GoldParticlePainter({
    required double animationValue,
    required int particleCount,
    required Size canvasSize,
    required int seed,
  }) {
    final random = Random(seed);
    final particles = List.generate(particleCount, (i) {
      final isGold = random.nextBool();
      return _GoldParticle(
        x: random.nextDouble() * canvasSize.width,
        y: random.nextDouble() * canvasSize.height,
        size: 1 + random.nextDouble() * 2, // 1px à 3px
        speed: 0.3 + random.nextDouble() * 0.7, // Vitesses variées
        opacity: 0.3 + random.nextDouble() * 0.7,
        color: isGold ? AppColors.gold : AppColors.yellow,
      );
    });
    return GoldParticlePainter._(
      animationValue: animationValue,
      particles: particles,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      // La particule monte depuis le bas
      final progress =
          (animationValue * particle.speed + particle.y / size.height) % 1.0;
      final currentY = size.height * (1.0 - progress);
      final currentX =
          particle.x + sin(progress * 4 * pi) * 10; // Légère oscillation X

      // Fade out quand la particule arrive en haut
      final fadeOut = progress > 0.8 ? (1.0 - progress) / 0.2 : 1.0;
      // Fade in quand la particule commence en bas
      final fadeIn = progress < 0.1 ? progress / 0.1 : 1.0;
      final alpha = particle.opacity * fadeOut * fadeIn;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(currentX % size.width, currentY),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GoldParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Widget qui encapsule le GoldParticlePainter avec animation infinie
class AnimatedGoldParticles extends StatefulWidget {
  final int particleCount;
  final Widget? child;

  const AnimatedGoldParticles({
    super.key,
    this.particleCount = 40,
    this.child,
  });

  @override
  State<AnimatedGoldParticles> createState() => _AnimatedGoldParticlesState();
}

class _AnimatedGoldParticlesState extends State<AnimatedGoldParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final int _seed = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: GoldParticlePainter(
            animationValue: _controller.value,
            particleCount: widget.particleCount,
            canvasSize: MediaQuery.of(context).size,
            seed: _seed,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
