import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_studio.dart';
import '../widgets/material_card_3d.dart';
import '../widgets/filter_chip_bar.dart';
import '../../providers/rentals_provider.dart';

/// Page catalogue des matériels avec grille 3D et filtres
/// Connectée au provider réel (plus de données mock)
class MaterialsPage extends ConsumerStatefulWidget {
  const MaterialsPage({super.key});

  @override
  ConsumerState<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends ConsumerState<MaterialsPage>
    with SingleTickerProviderStateMixin {
  int _selectedFilter = 0;
  late final AnimationController _fabController;
  late final Animation<double> _fabRotation;

  final _filters = [
    'Tous',
    'Appareils',
    'Objectifs',
    'Éclairage',
    'Trépieds',
    'Drones',
  ];

  final _filterCategories = {
    1: 'appareil',
    2: 'objectif',
    3: 'eclairage',
    4: 'trepied',
    5: 'drone',
  };

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabRotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );

    // Charger les matériels depuis l'API
    Future.microtask(() {
      ref.read(rentalsProvider.notifier).loadMaterials();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _applyFilter(int index) {
    setState(() => _selectedFilter = index);
    final categorie = _filterCategories[index];
    ref.read(rentalsProvider.notifier).loadMaterials(categorie: categorie);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalsProvider);
    final materials = state.materials;

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
                      child: Text(
                        'Matériels',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    // Bouton scanner QR
                    GestureDetector(
                      onTap: () => context.push('/scanner'),
                      child: Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.gold,
                          size: 22,
                        ),
                      ),
                    ),
                    // Bouton ajouter
                    RotationTransition(
                      turns: _fabRotation,
                      child: GestureDetector(
                        onTap: () {
                          context.push('/materials/new');
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.yellow.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Color(0xFF0D0D0D),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filtres
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: FadeInLeft(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 200),
                child: FilterChipBar(
                  filters: _filters,
                  selectedIndex: _selectedFilter,
                  onSelected: _applyFilter,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Grille de matériels
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: LoadingStudio(
                        message: 'Chargement des matériels...',
                      ),
                    )
                  : state.error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 64,
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.error!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => ref
                                    .read(rentalsProvider.notifier)
                                    .loadMaterials(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.yellow,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Réessayer',
                                      style: GoogleFonts.inter(
                                          color: const Color(0xFF0D0D0D),
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : materials.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 64,
                                    color:
                                        AppColors.gold.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun matériel trouvé',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Appuyez sur + pour ajouter du matériel',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.yellow,
                              backgroundColor: AppColors.surface,
                              onRefresh: () => ref
                                  .read(rentalsProvider.notifier)
                                  .loadMaterials(),
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: materials.length,
                                itemBuilder: (context, index) {
                                  final material = materials[index];
                                  return FadeInUp(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    delay: Duration(
                                        milliseconds: 80 * (index % 6)),
                                    child: MaterialCard3D(
                                      name: material.nom,
                                      brand: material.marque,
                                      category: material.categorie,
                                      dailyRate: material.tarifJournalier,
                                      status: material.etat,
                                      imageUrl: material.photos.isNotEmpty
                                          ? material.photos.first
                                          : null,
                                      onTap: () {
                                        context.push(
                                            '/materials/${material.id}');
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
