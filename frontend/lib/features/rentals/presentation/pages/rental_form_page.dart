import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/studio_button.dart';
import '../../../../core/widgets/studio_text_field.dart';
import '../../providers/rentals_provider.dart';
import '../../models/material_model.dart';

/// Formulaire de création d'un contrat de location
/// Peut recevoir un [materialId] pré-sélectionné
class RentalFormPage extends ConsumerStatefulWidget {
  final int? materialId;

  const RentalFormPage({super.key, this.materialId});

  @override
  ConsumerState<RentalFormPage> createState() => _RentalFormPageState();
}

class _RentalFormPageState extends ConsumerState<RentalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientNomController = TextEditingController();
  final _clientTelController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _cautionController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateDebut = DateTime.now();
  DateTime _dateFinPrevue = DateTime.now().add(const Duration(days: 1));
  MaterialItem? _selectedMaterial;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Charger les matériels pour le dropdown
    Future.microtask(() {
      ref.read(rentalsProvider.notifier).loadMaterials();
      // Si un materialId est passé, charger le détail
      if (widget.materialId != null) {
        ref.read(rentalsProvider.notifier).getMaterialDetail(widget.materialId!);
      }
    });
  }

  @override
  void dispose() {
    _clientNomController.dispose();
    _clientTelController.dispose();
    _clientEmailController.dispose();
    _cautionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Calculer le nombre de jours
  int get _nbJours {
    final diff = _dateFinPrevue.difference(_dateDebut).inDays;
    return diff > 0 ? diff : 1;
  }

  /// Calculer le montant total
  double get _montantTotal {
    if (_selectedMaterial == null) return 0;

    final tarif = _selectedMaterial!.tarifJournalier;
    // Appliquer le tarif hebdo si >= 7 jours, mensuel si >= 30 jours
    if (_nbJours >= 30 && _selectedMaterial!.tarifMensuel != null && _selectedMaterial!.tarifMensuel! > 0) {
      final mois = _nbJours / 30;
      return mois * _selectedMaterial!.tarifMensuel!;
    }
    if (_nbJours >= 7 && _selectedMaterial!.tarifHebdo != null && _selectedMaterial!.tarifHebdo! > 0) {
      final semaines = _nbJours / 7;
      return semaines * _selectedMaterial!.tarifHebdo!;
    }
    return _nbJours * tarif;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _dateDebut : _dateFinPrevue;
    final firstDate = isStart ? DateTime.now() : _dateDebut.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.yellow,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _dateDebut = picked;
          // S'assurer que la date de fin est après la date de début
          if (_dateFinPrevue.isBefore(_dateDebut) || _dateFinPrevue.isAtSameMomentAs(_dateDebut)) {
            _dateFinPrevue = _dateDebut.add(const Duration(days: 1));
          }
        } else {
          _dateFinPrevue = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un matériel',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'material_id': _selectedMaterial!.id,
      'client_nom': _clientNomController.text.trim(),
      'client_telephone': _clientTelController.text.trim(),
      'client_email': _clientEmailController.text.trim(),
      'date_debut': DateFormat('yyyy-MM-dd').format(_dateDebut),
      'date_fin_prevue': DateFormat('yyyy-MM-dd').format(_dateFinPrevue),
      'caution': double.tryParse(_cautionController.text) ?? 0,
      'montant_total': _montantTotal,
      if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
    };

    final success = await ref.read(rentalsProvider.notifier).createRental(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location créée avec succès !',
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
    final state = ref.watch(rentalsProvider);

    // Pré-sélectionner le matériel si l'ID est passé
    if (widget.materialId != null && _selectedMaterial == null && state.selectedMaterial != null) {
      _selectedMaterial = state.selectedMaterial;
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
            'Nouvelle location',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Sélection matériel ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _buildSection(
                title: 'Matériel',
                icon: Icons.camera_alt_rounded,
                children: [
                  _buildMaterialSelector(state.materials),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Infos client ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              child: _buildSection(
                title: 'Client',
                icon: Icons.person_rounded,
                children: [
                  StudioTextField(
                    controller: _clientNomController,
                    labelText: 'Nom du client *',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  StudioTextField(
                    controller: _clientTelController,
                    labelText: 'Téléphone',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  StudioTextField(
                    controller: _clientEmailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Dates ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              child: _buildSection(
                title: 'Période',
                icon: Icons.date_range_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Début',
                          date: _dateDebut,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          label: 'Fin prévue',
                          date: _dateFinPrevue,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: AppColors.yellow, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$_nbJours jour${_nbJours > 1 ? 's' : ''}',
                          style: GoogleFonts.montserrat(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Caution + Notes ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                title: 'Caution & Notes',
                icon: Icons.account_balance_wallet_rounded,
                children: [
                  StudioTextField(
                    controller: _cautionController,
                    labelText: 'Caution (FBu)',
                    prefixIcon: Icons.security_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  StudioTextField(
                    controller: _notesController,
                    labelText: 'Notes',
                    prefixIcon: Icons.note_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Résumé tarif ──
            if (_selectedMaterial != null)
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.15),
                        AppColors.yellow.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Matériel',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary)),
                          Text(_selectedMaterial!.nom,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Divider(
                          color: AppColors.surfaceLight, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tarif/jour',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary)),
                          Text(
                              '${_selectedMaterial!.tarifJournalier.toStringAsFixed(0)} FBu',
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                      const Divider(
                          color: AppColors.surfaceLight, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Durée',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary)),
                          Text('$_nbJours jour${_nbJours > 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                      const Divider(
                          color: AppColors.gold, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(
                            '${_montantTotal.toStringAsFixed(0)} FBu',
                            style: GoogleFonts.montserrat(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── Bouton soumettre ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 500),
              child: StudioButton(
                label: 'Créer le contrat',
                icon: Icons.assignment_turned_in_rounded,
                width: double.infinity,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Sélecteur de matériel
  Widget _buildMaterialSelector(List<MaterialItem> materials) {
    final availables = materials.where((m) => m.etat == 'disponible').toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMaterial?.id,
          hint: Text('Sélectionner un matériel',
              style: GoogleFonts.inter(color: AppColors.textHint)),
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.gold),
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          items: availables.map((m) {
            return DropdownMenuItem<int>(
              value: m.id,
              child: Row(
                children: [
                  Icon(_getCategoryIcon(m.categorie),
                      color: AppColors.gold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m.nom,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary, fontSize: 14)),
                        Text('${m.tarifJournalier.toStringAsFixed(0)} FBu/j',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id != null) {
              setState(() {
                _selectedMaterial = materials.firstWhere((m) => m.id == id);
              });
            }
          },
        ),
      ),
    );
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
      default:
        return Icons.devices_other_rounded;
    }
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

  /// Champ de date cliquable
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textHint, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_rounded,
                    color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
