import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bokeh_painter.dart';
import '../../../../core/widgets/gold_divider.dart';
import '../widgets/stat_card.dart';
import '../widgets/revenue_chart.dart';
import '../../../auth/providers/auth_provider.dart';

/// Page Dashboard — vue d'ensemble du studio
/// Stats animées, graphique revenus, dernières locations
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Bokeh en arrière-plan (opacité réduite)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: AnimatedBokehBackground(circleCount: 8),
            ),
          ),

          // Contenu
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header : Bonjour + date + avatar
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour, ${authState.prenom} 👋',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(now),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Avatar initiales
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold,
                              width: 1.5,
                            ),
                            color: AppColors.surface,
                          ),
                          child: Center(
                            child: Text(
                              authState.prenom.isNotEmpty
                                  ? authState.prenom[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Grille 2x2 de stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      // Card 1 : Matériels disponibles
                      FadeInLeft(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        child: const StatCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'Disponibles',
                          value: 12,
                          valueColor: AppColors.yellow,
                          iconColor: AppColors.gold,
                        ),
                      ),

                      // Card 2 : En location
                      FadeInRight(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        child: StatCard(
                          icon: Icons.camera_outlined,
                          label: 'En location',
                          value: 5,
                          valueColor: Colors.orange.shade400,
                          iconColor: Colors.orange.shade400,
                        ),
                      ),

                      // Card 3 : En retard
                      FadeInLeft(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 300),
                        child: const StatCard(
                          icon: Icons.warning_amber_rounded,
                          label: 'En retard',
                          value: 2,
                          valueColor: AppColors.error,
                          iconColor: AppColors.error,
                        ),
                      ),

                      // Card 4 : Revenus du mois
                      FadeInRight(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 400),
                        child: const StatCard(
                          icon: Icons.monetization_on_rounded,
                          label: 'Revenus du mois',
                          value: 850000,
                          suffix: ' FBu',
                          valueColor: AppColors.gold,
                          iconColor: AppColors.gold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Graphique revenus
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 500),
                    child: const RevenueChart(
                      values: [120000, 85000, 200000, 150000, 180000, 95000, 220000],
                      labels: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section dernières locations
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dernières locations',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const GoldDivider(),
                        const SizedBox(height: 12),
                        // Exemples de locations récentes
                        _RecentRentalItem(
                          materialName: 'Canon EOS R5',
                          clientName: 'Jean Baptiste',
                          date: 'Il y a 2 heures',
                          status: 'Active',
                          statusColor: AppColors.success,
                        ),
                        const SizedBox(height: 8),
                        _RecentRentalItem(
                          materialName: 'Godox AD600 Pro',
                          clientName: 'Marie Claire',
                          date: 'Hier',
                          status: 'En retard',
                          statusColor: AppColors.error,
                        ),
                        const SizedBox(height: 8),
                        _RecentRentalItem(
                          materialName: 'Sony 24-70mm f/2.8',
                          clientName: 'Pierre Nduwayo',
                          date: 'Il y a 3 jours',
                          status: 'Terminée',
                          statusColor: AppColors.textHint,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour une location récente dans la liste
class _RecentRentalItem extends StatelessWidget {
  final String materialName;
  final String clientName;
  final String date;
  final String status;
  final Color statusColor;

  const _RecentRentalItem({
    required this.materialName,
    required this.clientName,
    required this.date,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.gold.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        children: [
          // Icône matériel
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  materialName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$clientName · $date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
