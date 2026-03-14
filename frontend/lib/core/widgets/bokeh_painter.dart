import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Cercle bokeh individuel avec position, taille, opacité et vitesse
class _BokehCircle {
  double x;
  double y;
  final double radius;
  final double opacity;
  final double speedX;
  final double speedY;
  final double phaseOffset;

  _BokehCircle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.phaseOffset,
  });
}

/// Effet bokeh doré animé en arrière-plan
/// Cercles flous dorés qui bougent lentement avec oscillation
class BokehPainter extends CustomPainter {
  final double animationValue;
  final List<_BokehCircle> _circles;

  BokehPainter._({
    required this.animationValue,
    required List<_BokehCircle> circles,
  }) : _circles = circles;

  /// Crée un BokehPainter avec des cercles générés aléatoirement
  factory BokehPainter({
    required double animationValue,
    required int circleCount,
    required Size canvasSize,
    required int seed,
  }) {
    final random = Random(seed);
    final circles = List.generate(circleCount, (i) {
      return _BokehCircle(
        x: random.nextDouble() * canvasSize.width,
        y: random.nextDouble() * canvasSize.height,
        radius: 20 + random.nextDouble() * 60, // 20px à 80px
        opacity: 0.1 + random.nextDouble() * 0.2, // 0.1 à 0.3
        speedX: -0.3 + random.nextDouble() * 0.6,
        speedY: -0.2 + random.nextDouble() * 0.4,
        phaseOffset: random.nextDouble() * 2 * pi,
      );
    });
    return BokehPainter._(animationValue: animationValue, circles: circles);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final circle in _circles) {
      // Position animée avec sin wave pour l'oscillation verticale
      final dx = circle.x + circle.speedX * animationValue * size.width;
      final dy = circle.y +
          sin(animationValue * 2 * pi + circle.phaseOffset) *
              30 *
              circle.speedY;

      // Garder dans les limites
      final wrappedX = dx % size.width;
      final wrappedY = dy % size.height;

      final paint = Paint()
        ..color = AppColors.gold.withValues(alpha: circle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(Offset(wrappedX, wrappedY), circle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BokehPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Widget qui encapsule le BokehPainter avec son AnimationController
class AnimatedBokehBackground extends StatefulWidget {
  final int circleCount;
  final Widget? child;

  const AnimatedBokehBackground({
    super.key,
    this.circleCount = 10,
    this.child,
  });

  @override
  State<AnimatedBokehBackground> createState() =>
      _AnimatedBokehBackgroundState();
}

class _AnimatedBokehBackgroundState extends State<AnimatedBokehBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final int _seed = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
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
          painter: BokehPainter(
            animationValue: _controller.value,
            circleCount: widget.circleCount,
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
