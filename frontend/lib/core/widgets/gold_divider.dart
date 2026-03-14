import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Séparateur doré élégant — dégradé transparent → gold → transparent
class GoldDivider extends StatelessWidget {
  final double height;
  final double indent;
  final double endIndent;

  const GoldDivider({
    super.key,
    this.height = 0.5,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.gold,
              Colors.transparent,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
