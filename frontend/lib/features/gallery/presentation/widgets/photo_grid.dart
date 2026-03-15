import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';

/// Grille masonry réutilisable pour les photos
/// Gère le lazy loading et les animations stagger
class PhotoGrid extends StatelessWidget {
  final List<String> photoUrls;
  final void Function(int index) onPhotoTap;

  const PhotoGrid({
    super.key,
    required this.photoUrls,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.all(4),
      itemCount: photoUrls.length,
      itemBuilder: (context, index) {
        return FadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * (index % 12)),
          child: GestureDetector(
            onTap: () => onPhotoTap(index),
            child: Hero(
              tag: 'photo_$index',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  // Hauteurs variées pour l'effet masonry
                  height: _getItemHeight(index),
                  color: AppColors.surfaceLight,
                  child: photoUrls[index].isNotEmpty
                      ? Image.network(
                          photoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildLoading();
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getItemHeight(int index) {
    // Alterner les hauteurs pour l'effet masonry
    final heights = [150.0, 200.0, 170.0, 220.0, 180.0, 160.0];
    return heights[index % heights.length];
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          color: AppColors.gold.withValues(alpha: 0.3),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}
