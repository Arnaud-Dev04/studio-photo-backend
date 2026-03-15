
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';

/// Card de matériel avec effet de rotation 3D au tap
/// Photo, overlay nom/marque, badge statut, icône QR, tarif
class MaterialCard3D extends StatefulWidget {
  final String name;
  final String brand;
  final String category;
  final double dailyRate;
  final String status; // disponible, loue, maintenance, en_retard
  final String? imageUrl;
  final VoidCallback? onTap;

  const MaterialCard3D({
    super.key,
    required this.name,
    required this.brand,
    required this.category,
    required this.dailyRate,
    required this.status,
    this.imageUrl,
    this.onTap,
  });

  @override
  State<MaterialCard3D> createState() => _MaterialCard3DState();
}

class _MaterialCard3DState extends State<MaterialCard3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationY = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  StatusType get _statusType {
    switch (widget.status) {
      case 'disponible':
        return StatusType.disponible;
      case 'loue':
        return StatusType.loue;
      case 'en_retard':
        return StatusType.enRetard;
      case 'maintenance':
        return StatusType.maintenance;
      default:
        return StatusType.disponible;
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case 'disponible':
        return 'Disponible';
      case 'loue':
        return 'Loué';
      case 'en_retard':
        return 'En retard';
      case 'maintenance':
        return 'Maintenance';
      default:
        return widget.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateY(_rotationY.value), // Rotation Y
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Image ou placeholder
                AspectRatio(
                  aspectRatio: 0.85,
                  child: widget.imageUrl != null
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),

                // Overlay dégradé en bas
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.brand,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Badge statut en haut à droite
                Positioned(
                  top: 8,
                  right: 8,
                  child: StatusBadge(
                    label: _statusLabel,
                    type: _statusType,
                  ),
                ),

                // Icône QR en haut à gauche
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ),
                ),

                // Tarif en bas à droite
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.dailyRate.toStringAsFixed(0)} FBu/j',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.yellow,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          size: 48,
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.category.toLowerCase()) {
      case 'appareil':
        return Icons.camera_alt_rounded;
      case 'objectif':
        return Icons.camera_rounded;
      case 'flash':
      case 'éclairage':
        return Icons.flash_on_rounded;
      case 'trépied':
        return Icons.straighten_rounded;
      case 'drone':
        return Icons.airplanemode_active_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }
}
