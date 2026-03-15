import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Flash Godox — effet de flash studio lors de la confirmation d'une action
/// Un flash blanc/jaune couvre brièvement l'écran
class FlashOverlay extends StatefulWidget {
  final Widget child;
  final FlashOverlayController controller;

  const FlashOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<FlashOverlay> createState() => _FlashOverlayState();
}

class _FlashOverlayState extends State<FlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450), // 150ms + 300ms
    );

    // Montée rapide (0→0.7 en 33%) puis descente lente (0.7→0 en 67%)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.7),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 0.0),
        weight: 67,
      ),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    widget.controller._attach(this);
  }

  void _triggerFlash() {
    _animController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Overlay flash
        AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, _) {
            if (_opacityAnimation.value == 0) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: AppColors.yellow
                      .withValues(alpha: _opacityAnimation.value),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Contrôleur pour déclencher le flash Godox depuis l'extérieur
class FlashOverlayController {
  _FlashOverlayState? _state;

  void _attach(_FlashOverlayState state) {
    _state = state;
  }

  /// Déclenche le flash
  void flash() {
    _state?._triggerFlash();
  }

  void dispose() {
    _state = null;
  }
}
