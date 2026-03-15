import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Loader personnalisé du studio — cercle doré + particules tournantes
/// Remplace CircularProgressIndicator basique
class LoadingStudio extends StatefulWidget {
  final double size;
  final String? message;

  const LoadingStudio({
    super.key,
    this.size = 60,
    this.message,
  });

  @override
  State<LoadingStudio> createState() => _LoadingStudioState();
}

class _LoadingStudioState extends State<LoadingStudio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _LoadingPainter(
                  progress: _controller.value,
                  size: widget.size,
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final double progress;
  final double size;

  _LoadingPainter({required this.progress, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size / 2 - 4;

    // Arc doré principal qui tourne
    final arcPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final startAngle = progress * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      pi * 1.2,
      false,
      arcPaint,
    );

    // Second arc plus fin et plus clair (sens opposé)
    final arcPaint2 = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -startAngle,
      pi * 0.8,
      false,
      arcPaint2,
    );

    // 6 particules dorées qui orbitent
    for (int i = 0; i < 6; i++) {
      final angle = startAngle + (i * pi / 3);
      final particleRadius = radius + 2;
      final px = center.dx + cos(angle) * particleRadius;
      final py = center.dy + sin(angle) * particleRadius;
      final particleSize = 1.5 + sin(progress * 2 * pi + i) * 0.5;

      final particlePaint = Paint()
        ..color = AppColors.yellow.withValues(
            alpha: 0.5 + sin(progress * 2 * pi + i * 1.5) * 0.3);

      canvas.drawCircle(Offset(px, py), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
