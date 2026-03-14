import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_studio.dart';
import '../widgets/photo_grid.dart';
import 'photo_viewer_page.dart';

/// Page galerie photo — fond noir immersif, grille masonry, FAB upload
class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late final AnimationController _pulseController;

  // Données de démonstration — URLs de photos placeholder
  final _photoUrls = List.generate(
    18,
    (_) => '', // Vide = placeholder, sera remplacé par des URLs Cloudinary
  );

  // Albums de démonstration
  final _albums = [
    {'title': 'Mariage Nduwayo', 'count': 127, 'date': '12 Mars 2025'},
    {'title': 'Séance Portrait', 'count': 45, 'date': '10 Mars 2025'},
    {'title': 'Événement Corporate', 'count': 89, 'date': '8 Mars 2025'},
  ];

  int _selectedAlbum = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Simuler le chargement
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galerie',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_photoUrls.length} photos',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sélecteur d'albums
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _albums.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  final isSelected = index == _selectedAlbum;
                  return FadeInLeft(
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: 100 * index),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedAlbum = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.yellow.withValues(alpha: 0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.yellow
                                : AppColors.gold.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              album['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.yellow
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${album['count']} photos · ${album['date']}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Grille de photos
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: LoadingStudio(message: 'Chargement des photos...'),
                    )
                  : PhotoGrid(
                      photoUrls: _photoUrls,
                      onPhotoTap: (index) {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => PhotoViewerPage(
                              photoUrls: _photoUrls,
                              initialIndex: index,
                            ),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // FAB upload
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 500),
        delay: const Duration(milliseconds: 700),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow
                        .withValues(alpha: 0.2 + _pulseController.value * 0.15),
                    blurRadius: 12 + _pulseController.value * 8,
                    spreadRadius: _pulseController.value * 4,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: FloatingActionButton(
            onPressed: () {
              // TODO: Ouvrir upload
            },
            backgroundColor: AppColors.yellow,
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Color(0xFF0D0D0D),
            ),
          ),
        ),
      ),
    );
  }
}
