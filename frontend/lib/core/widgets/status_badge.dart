import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Badge de statut animé pour les matériels
/// Disponible : vert + point clignotant | Loué : rouge
/// En retard : rouge + pulse | Maintenance : jaune
class StatusBadge extends StatefulWidget {
  final String label;
  final StatusType type;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

enum StatusType { disponible, loue, enRetard, maintenance }

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation clignotante pour disponible et en retard
    if (widget.type == StatusType.disponible ||
        widget.type == StatusType.enRetard) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _badgeColor {
    switch (widget.type) {
      case StatusType.disponible:
        return AppColors.success;
      case StatusType.loue:
        return AppColors.error;
      case StatusType.enRetard:
        return AppColors.error;
      case StatusType.maintenance:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _badgeColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Point clignotant animé
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _badgeColor.withValues(
                    alpha: widget.type == StatusType.disponible ||
                            widget.type == StatusType.enRetard
                        ? _pulseAnimation.value
                        : 1.0,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: _badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
