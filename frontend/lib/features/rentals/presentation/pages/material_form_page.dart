import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/studio_button.dart';
import '../../../../core/widgets/studio_text_field.dart';
import '../../providers/rentals_provider.dart';
import '../../models/material_model.dart';

/// Formulaire d'ajout / édition d'un matériel
/// Si [material] est null → mode création, sinon → mode édition
class MaterialFormPage extends ConsumerStatefulWidget {
  final MaterialItem? material;

  const MaterialFormPage({super.key, this.material});

  @override
  ConsumerState<MaterialFormPage> createState() => _MaterialFormPageState();
}

class _MaterialFormPageState extends ConsumerState<MaterialFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _tarifJourController = TextEditingController();
  final _tarifSemaineController = TextEditingController();
  final _tarifMoisController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategorie = 'appareil';
  DateTime? _dateAcquisition;
  bool _isSubmitting = false;
  final List<String> _selectedPhotoPaths = [];

  bool get _isEditing => widget.material != null;

  static const _categories = {
    'appareil': 'Appareil photo',
    'objectif': 'Objectif',
    'eclairage': 'Éclairage',
    'trepied': 'Trépied',
    'drone': 'Drone',
    'studio': 'Studio',
    'accessoire': 'Accessoire',
    'autre': 'Autre',
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final m = widget.material!;
      _nomController.text = m.nom;
      _marqueController.text = m.marque;
      _modeleController.text = m.modele;
      _numeroSerieController.text = m.numeroSerie ?? '';
      _tarifJourController.text = m.tarifJournalier.toStringAsFixed(0);
      _tarifSemaineController.text = m.tarifHebdo?.toStringAsFixed(0) ?? '';
      _tarifMoisController.text = m.tarifMensuel?.toStringAsFixed(0) ?? '';
      _selectedCategorie = m.categorie;
      _dateAcquisition = m.dateAcquisition;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _numeroSerieController.dispose();
    _tarifJourController.dispose();
    _tarifSemaineController.dispose();
    _tarifMoisController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateAcquisition ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
      setState(() => _dateAcquisition = picked);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedPhotoPaths.add(image.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'nom': _nomController.text.trim(),
      'marque': _marqueController.text.trim(),
      'modele': _modeleController.text.trim(),
      'categorie': _selectedCategorie,
      'tarif_journalier': double.tryParse(_tarifJourController.text) ?? 0,
    };

    if (_numeroSerieController.text.isNotEmpty) {
      data['numero_serie'] = _numeroSerieController.text.trim();
    }
    if (_tarifSemaineController.text.isNotEmpty) {
      data['tarif_hebdomadaire'] = double.tryParse(_tarifSemaineController.text) ?? 0;
    }
    if (_tarifMoisController.text.isNotEmpty) {
      data['tarif_mensuel'] = double.tryParse(_tarifMoisController.text) ?? 0;
    }
    if (_descriptionController.text.isNotEmpty) {
      data['description'] = _descriptionController.text.trim();
    }
    if (_dateAcquisition != null) {
      data['date_acquisition'] = DateFormat('yyyy-MM-dd').format(_dateAcquisition!);
    }

    final notifier = ref.read(rentalsProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateMaterial(widget.material!.id, data);
    } else {
      success = await notifier.createMaterial(data);
    }

    if (success && mounted) {
      // Upload des photos si nouvelles
      // Note: pour l'édition, les photos existantes sont déjà sur le serveur
      // Les nouvelles photos seront uploadées après la création
      context.pop(true);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _isEditing ? 'Modifier le matériel' : 'Nouveau matériel',
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
            // ── Infos principales ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _buildSection(
                title: 'Informations',
                icon: Icons.info_outline_rounded,
                children: [
                  StudioTextField(
                    controller: _nomController,
                    labelText: 'Nom du matériel *',
                    prefixIcon: Icons.camera_alt_rounded,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StudioTextField(
                          controller: _marqueController,
                          labelText: 'Marque *',
                          prefixIcon: Icons.branding_watermark_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StudioTextField(
                          controller: _modeleController,
                          labelText: 'Modèle *',
                          prefixIcon: Icons.device_hub_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StudioTextField(
                    controller: _numeroSerieController,
                    labelText: 'Numéro de série',
                    prefixIcon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown catégorie
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  StudioTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    prefixIcon: Icons.description_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tarifs ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              child: _buildSection(
                title: 'Tarifs (FBu)',
                icon: Icons.payments_rounded,
                children: [
                  StudioTextField(
                    controller: _tarifJourController,
                    labelText: 'Tarif journalier *',
                    prefixIcon: Icons.today_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Le tarif journalier est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StudioTextField(
                          controller: _tarifSemaineController,
                          labelText: 'Hebdomadaire',
                          prefixIcon: Icons.date_range_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StudioTextField(
                          controller: _tarifMoisController,
                          labelText: 'Mensuel',
                          prefixIcon: Icons.calendar_month_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Date d'acquisition ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              child: _buildSection(
                title: 'Acquisition',
                icon: Icons.calendar_today_rounded,
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded,
                              color: AppColors.gold, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            _dateAcquisition != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(_dateAcquisition!)
                                : 'Sélectionner une date',
                            style: GoogleFonts.inter(
                              color: _dateAcquisition != null
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Photos ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                title: 'Photos',
                icon: Icons.photo_library_rounded,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Photos existantes (en mode édition)
                      if (_isEditing)
                        ...widget.material!.photos.map((url) =>
                            _buildPhotoThumbnail(networkUrl: url)),
                      // Nouvelles photos sélectionnées
                      ..._selectedPhotoPaths
                          .map((path) => _buildPhotoThumbnail(localPath: path)),
                      // Bouton ajouter
                      _buildAddPhotoButton(),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Bouton Soumettre ──
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 400),
              child: StudioButton(
                label: _isEditing ? 'Enregistrer les modifications' : 'Ajouter le matériel',
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
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

  /// Section regroupée avec titre
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

  /// Dropdown catégorie
  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategorie,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.gold),
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          items: _categories.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(e.key),
                            color: AppColors.gold, size: 20),
                        const SizedBox(width: 12),
                        Text(e.value),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedCategorie = v);
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
      case 'studio':
        return Icons.store_rounded;
      case 'accessoire':
        return Icons.cable_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  /// Thumbnail d'une photo (réseau ou locale)
  Widget _buildPhotoThumbnail({String? networkUrl, String? localPath}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 80,
            color: AppColors.surfaceLight,
            child: networkUrl != null
                ? Image.network(networkUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded,
                              color: AppColors.textHint),
                        ))
                : const Center(
                    child: Icon(Icons.image_rounded,
                        color: AppColors.gold, size: 32)),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () {
              if (localPath != null) {
                setState(() => _selectedPhotoPaths.remove(localPath));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// Bouton ajouter photo
  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppColors.gold, size: 24),
            SizedBox(height: 4),
            Text(
              'Ajouter',
              style: TextStyle(color: AppColors.textHint, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
