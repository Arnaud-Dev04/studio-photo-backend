import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/studio_button.dart';
import '../../../../core/widgets/loading_studio.dart';
import '../../providers/rentals_provider.dart';
import '../../models/material_model.dart';

/// Page de détail d'un matériel — carrousel photos, QR code, historique locations
class MaterialDetailPage extends ConsumerStatefulWidget {
  final int materialId;

  const MaterialDetailPage({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends ConsumerState<MaterialDetailPage> {
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    // Charger le détail du matériel
    Future.microtask(() {
      ref.read(rentalsProvider.notifier).getMaterialDetail(widget.materialId);
    });
  }

  StatusType _getStatusType(String status) {
    switch (status) {
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'disponible':
        return 'Disponible';
      case 'loue':
        return 'Loué';
      case 'en_retard':
        return 'En retard';
      case 'maintenance':
        return 'Maintenance';
      case 'hors_service':
        return 'Hors service';
      default:
        return status;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'appareil':
        return 'Appareil photo';
      case 'objectif':
        return 'Objectif';
      case 'eclairage':
        return 'Éclairage';
      case 'trepied':
        return 'Trépied';
      case 'drone':
        return 'Drone';
      case 'studio':
        return 'Studio';
      case 'accessoire':
        return 'Accessoire';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'appareil':
        return Icons.camera_alt_rounded;
      case 'objectif':
        return Icons.camera_rounded;
      case 'eclairage':
        return Icons.flash_on_rounded;
      case 'trepied':
        return Icons.straighten_rounded;
      case 'drone':
        return Icons.airplanemode_active_rounded;
      case 'studio':
        return Icons.store_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  void _confirmDelete(MaterialItem material) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer ce matériel ?',
          style: GoogleFonts.montserrat(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Cette action est irréversible. Le matériel "${material.nom}" sera définitivement supprimé.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(rentalsProvider.notifier)
                  .deleteMaterial(material.id);
              if (success && mounted) {
                context.pop();
              }
            },
            child: Text('Supprimer',
                style: GoogleFonts.inter(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalsProvider);
    final material = state.selectedMaterial;

    if (state.isLoading && material == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: LoadingStudio(message: 'Chargement du matériel...'),
        ),
      );
    }

    if (material == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gold),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.gold.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Matériel non trouvé',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar avec carrousel photos ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: FadeInLeft(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ),
            actions: [
              FadeInRight(
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppColors.textPrimary),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            context.push('/materials/${material.id}/edit');
                          case 'delete':
                            _confirmDelete(material);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded,
                                  color: AppColors.gold, size: 20),
                              const SizedBox(width: 12),
                              Text('Modifier',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_rounded,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: 12),
                              Text('Supprimer',
                                  style:
                                      GoogleFonts.inter(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPhotoCarousel(material),
            ),
          ),

          // ── Contenu scrollable ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et badge
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            material.nom,
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: _getStatusLabel(material.etat),
                          type: _getStatusType(material.etat),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Marque / Modèle
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      '${material.marque} — ${material.modele}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Infos détaillées ──
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                    child: _buildInfoSection(material),
                  ),

                  const SizedBox(height: 24),

                  // ── Tarifs ──
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                    child: _buildTarifsSection(material),
                  ),

                  const SizedBox(height: 24),

                  // ── QR Code ──
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 400),
                    child: _buildQrSection(material),
                  ),

                  const SizedBox(height: 32),

                  // ── Bouton Louer ──
                  if (material.etat == 'disponible')
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 500),
                      child: StudioButton(
                        label: 'Louer ce matériel',
                        icon: Icons.assignment_rounded,
                        width: double.infinity,
                        onPressed: () {
                          context.push('/rentals/new?materialId=${material.id}');
                        },
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carrousel de photos du matériel
  Widget _buildPhotoCarousel(MaterialItem material) {
    if (material.photos.isEmpty) {
      return Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(material.categorie),
                size: 72,
                color: AppColors.gold.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune photo',
                style: GoogleFonts.inter(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: material.photos.length,
          onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
          itemBuilder: (context, index) {
            return Image.network(
              material.photos[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceLight,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded,
                      size: 48, color: AppColors.textHint),
                ),
              ),
            );
          },
        ),
        // Dégradé bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
        ),
        // Indicateurs
        if (material.photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                material.photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPhotoIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPhotoIndex
                        ? AppColors.yellow
                        : AppColors.textHint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Section informations détaillées
  Widget _buildInfoSection(MaterialItem material) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              Icons.category_rounded, 'Catégorie', _getCategoryLabel(material.categorie)),
          if (material.numeroSerie != null)
            _buildInfoRow(
                Icons.tag_rounded, 'N° Série', material.numeroSerie!),
          if (material.dateAcquisition != null)
            _buildInfoRow(Icons.calendar_today_rounded, 'Acquisition',
                _formatDate(material.dateAcquisition!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label :',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Section tarifs
  Widget _buildTarifsSection(MaterialItem material) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tarifs',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTarifCard('Jour', material.tarifJournalier),
              const SizedBox(width: 12),
              _buildTarifCard('Semaine', material.tarifHebdo),
              const SizedBox(width: 12),
              _buildTarifCard('Mois', material.tarifMensuel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarifCard(String period, double? amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              period,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount != null && amount > 0
                  ? '${amount.toStringAsFixed(0)} FBu'
                  : '—',
              style: GoogleFonts.montserrat(
                color: AppColors.yellow,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section QR Code
  Widget _buildQrSection(MaterialItem material) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: 'STUDIO_MATERIAL:${material.id}',
              version: QrVersions.auto,
              size: 100,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR Code',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scannez ce QR code pour accéder rapidement à la fiche de ce matériel.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
