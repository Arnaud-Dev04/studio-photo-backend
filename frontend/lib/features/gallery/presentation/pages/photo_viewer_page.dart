import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Visionneuse photo plein écran
/// Hero animation, swipe horizontal, pinch-to-zoom, barre d'actions
class PhotoViewerPage extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const PhotoViewerPage({
    super.key,
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView avec photos
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photoUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'photo_$index',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: widget.photoUrls[index].isNotEmpty
                        ? Image.network(
                            widget.photoUrls[index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textHint,
                              size: 64,
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(
                              Icons.photo_outlined,
                              color: AppColors.textHint,
                              size: 64,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),

          // Bouton fermer en haut à gauche
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _ActionButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Compteur de photos en haut
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.photoUrls.length}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Barre d'actions en bas
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.download_rounded,
                  onTap: () {
                    // TODO: Télécharger la photo
                  },
                ),
                const SizedBox(width: 20),
                _ActionButton(
                  icon: Icons.share_rounded,
                  onTap: () {
                    // TODO: Partager la photo
                  },
                ),
                const SizedBox(width: 20),
                _ActionButton(
                  icon: Icons.favorite_border_rounded,
                  onTap: () {
                    // TODO: Marquer en favori
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action rond semi-transparent
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}
