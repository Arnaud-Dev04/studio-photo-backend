import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/studio_button.dart';
import '../../../../core/widgets/studio_text_field.dart';
import '../../../../core/widgets/loading_studio.dart';
import '../../providers/rentals_provider.dart';
import '../../models/rental_model.dart';

/// Écran de retour d'un matériel loué
/// Inspection, état, photos dommages, notes
class RentalReturnPage extends ConsumerStatefulWidget {
  final int rentalId;

  const RentalReturnPage({super.key, required this.rentalId});

  @override
  ConsumerState<RentalReturnPage> createState() => _RentalReturnPageState();
}

class _RentalReturnPageState extends ConsumerState<RentalReturnPage> {
  final _notesController = TextEditingController();
  String _etatRetour = 'Bon état';
  String _etatMateriel = 'disponible'; // disponible ou maintenance
  bool _isSubmitting = false;
  Rental? _rental;
  bool _isLoading = true;

  final _etatsRetour = [
    'Bon état',
    'Usure normale',
    'Dommages légers',
    'Dommages importants',
  ];

  @override
  void initState() {
    super.initState();
    _loadRental();
  }

  Future<void> _loadRental() async {
    try {
      final api = ref.read(rentalsProvider.notifier);
      // Charger les locations pour trouver celle-ci
      await api.loadRentals();
      final state = ref.read(rentalsProvider);
      final rental = state.rentals.where((r) => r.id == widget.rentalId).firstOrNull;
      if (mounted) {
        setState(() {
          _rental = rental;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final data = {
      'etat_retour': _etatRetour,
      'etat_materiel': _etatMateriel,
      if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
    };

    final success =
        await ref.read(rentalsProvider.notifier).returnRental(widget.rentalId, data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retour enregistré avec succès !',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: LoadingStudio(message: 'Chargement de la location...'),
        ),
      );
    }

    if (_rental == null) {
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
          child: Text('Location non trouvée',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: Text(
            'Retour matériel',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Résumé de la location ──
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: _buildRentalSummary(),
          ),

          const SizedBox(height: 20),

          // ── État au retour ──
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 100),
            child: _buildSection(
              title: 'État au retour',
              icon: Icons.checklist_rounded,
              children: [
                ..._etatsRetour.map((etat) => _buildRadioTile(
                      value: etat,
                      groupValue: _etatRetour,
                      onChanged: (v) => setState(() => _etatRetour = v!),
                      icon: _getEtatIcon(etat),
                      color: _getEtatColor(etat),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── État matériel après retour ──
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            child: _buildSection(
              title: 'Disponibilité après retour',
              icon: Icons.settings_rounded,
              children: [
                _buildRadioTile(
                  value: 'disponible',
                  groupValue: _etatMateriel,
                  onChanged: (v) => setState(() => _etatMateriel = v!),
                  label: 'Remettre disponible',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
                _buildRadioTile(
                  value: 'maintenance',
                  groupValue: _etatMateriel,
                  onChanged: (v) => setState(() => _etatMateriel = v!),
                  label: 'Envoyer en maintenance',
                  icon: Icons.build_rounded,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Notes ──
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 300),
            child: _buildSection(
              title: 'Notes',
              icon: Icons.note_rounded,
              children: [
                StudioTextField(
                  controller: _notesController,
                  hintText: 'Observations sur le retour...',
                  maxLines: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Bouton confirmer ──
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 400),
            child: StudioButton(
              label: 'Confirmer le retour',
              icon: Icons.assignment_return_rounded,
              width: double.infinity,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Résumé de la location
  Widget _buildRentalSummary() {
    final rental = _rental!;
    final isOverdue = rental.isOverdue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.gold.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_rounded,
                color: isOverdue ? AppColors.error : AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Location #${rental.id}',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isOverdue ? AppColors.error : AppColors.gold,
                ),
              ),
              if (isOverdue) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('EN RETARD',
                      style: GoogleFonts.montserrat(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Client', rental.clientNom),
          _buildSummaryRow(
              'Début', _formatDate(rental.dateDebut)),
          _buildSummaryRow(
              'Fin prévue', _formatDate(rental.dateFinPrevue)),
          _buildSummaryRow(
              'Montant', '${rental.montantTotal.toStringAsFixed(0)} FBu'),
          if (rental.caution > 0)
            _buildSummaryRow(
                'Caution', '${rental.caution.toStringAsFixed(0)} FBu'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Radio tile personnalisé
  Widget _buildRadioTile({
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    String? label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textHint, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label ?? value,
                style: GoogleFonts.inter(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Section regroupée
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  IconData _getEtatIcon(String etat) {
    switch (etat) {
      case 'Bon état':
        return Icons.check_circle_rounded;
      case 'Usure normale':
        return Icons.info_rounded;
      case 'Dommages légers':
        return Icons.warning_amber_rounded;
      case 'Dommages importants':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Color _getEtatColor(String etat) {
    switch (etat) {
      case 'Bon état':
        return AppColors.success;
      case 'Usure normale':
        return AppColors.info;
      case 'Dommages légers':
        return AppColors.warning;
      case 'Dommages importants':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
