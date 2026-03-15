import 'package:flutter/material.dart';

/// Widget réutilisable qui fait léviter son enfant avec une oscillation verticale
/// Mouvement infini : ±amplitude pixels, durée configurable
class LevitatingWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  final Curve curve;

  const LevitatingWidget({
    super.key,
    required this.child,
    this.amplitude = 8.0,
    this.duration = const Duration(milliseconds: 2000),
    this.curve = Curves.easeInOut,
  });

  @override
  State<LevitatingWidget> createState() => _LevitatingWidgetState();
}

class _LevitatingWidgetState extends State<LevitatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.amplitude,
      end: widget.amplitude,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
