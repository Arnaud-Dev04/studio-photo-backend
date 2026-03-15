import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Texte avec effet shimmer doré — utilisé pour les titres premium
class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    super.key,
    required this.text,
    this.style,
    this.baseColor = AppColors.gold,
    this.highlightColor = AppColors.goldLight,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 2000),
      child: Text(
        text,
        style: style ??
            Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.gold,
                ),
      ),
    );
  }
}

/// Widget générique avec effet shimmer doré
class ShimmerWidget extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor = AppColors.gold,
    this.highlightColor = AppColors.goldLight,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 2000),
      child: child,
    );
  }
}
