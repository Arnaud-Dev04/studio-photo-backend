import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compteur animé qui incrémente de 0 jusqu'à la valeur cible
/// Utilisé pour les statistiques du dashboard et les montants finance
class AnimatedCounter extends StatefulWidget {
  final int targetValue;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;
  final bool useNumberFormat;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOut,
    this.prefix,
    this.suffix,
    this.useNumberFormat = true,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  final _numberFormat = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.targetValue.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = Tween<double>(
        begin: oldWidget.targetValue.toDouble(),
        end: widget.targetValue.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _controller
        ..reset()
        ..forward();
    }
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
        final value = _animation.value.round();
        final formatted = widget.useNumberFormat
            ? _numberFormat.format(value)
            : value.toString();
        return Text(
          '${widget.prefix ?? ''}$formatted${widget.suffix ?? ''}',
          style: widget.style ?? Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}
