import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/studio_button.dart';
import '../../../../core/widgets/studio_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/loading_studio.dart';
import '../../providers/finance_provider.dart';

/// Page Finance — Dashboard CA, factures, dépenses
class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    Future.microtask(() {
      ref.read(financeProvider.notifier).loadDashboard();
      ref.read(financeProvider.notifier).loadInvoices();
      ref.read(financeProvider.notifier).loadExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Finance',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dashboard Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Row(
                  children: [
                    _buildDashCard(
                      'CA du mois',
                      _formatMoney(state.caMois),
                      Icons.trending_up_rounded,
                      AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _buildDashCard(
                      'Dépenses',
                      _formatMoney(state.depensesMois),
                      Icons.trending_down_rounded,
                      AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    _buildDashCard(
                      'Bénéfice',
                      _formatMoney(state.beneficeMois),
                      Icons.account_balance_rounded,
                      state.beneficeMois >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Info en attente
            if (state.facturesEnAttente > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${state.facturesEnAttente} facture(s) en attente — ${_formatMoney(state.montantEnAttente)}',
                            style: GoogleFonts.inter(
                                color: AppColors.warning, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Tabs
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: const Color(0xFF0D0D0D),
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Factures'),
                    Tab(text: 'Dépenses'),
                    Tab(text: 'Résumé'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Contenu
            Expanded(
              child: state.isLoading
                  ? const Center(child: LoadingStudio())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInvoicesTab(state),
                        _buildExpensesTab(state),
                        _buildSummaryTab(state),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab < 2
          ? FloatingActionButton(
              backgroundColor: AppColors.yellow,
              onPressed: () {
                if (_selectedTab == 0) {
                  _showCreateInvoiceDialog();
                } else {
                  _showCreateExpenseDialog();
                }
              },
              child: const Icon(Icons.add_rounded, color: Color(0xFF0D0D0D)),
            )
          : null,
    );
  }

  Widget _buildDashCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ───────── Factures ─────────
  Widget _buildInvoicesTab(FinanceState state) {
    if (state.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: AppColors.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucune facture',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(financeProvider.notifier).loadInvoices(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.invoices.length,
        itemBuilder: (context, index) {
          final inv = state.invoices[index];
          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: 50 * (index % 10)),
            child: _buildInvoiceCard(inv),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> inv) {
    final statutLabels = {
      'non_paye': 'Non payé',
      'partiel': 'Partiel',
      'paye': 'Payé',
    };
    final statutTypes = {
      'non_paye': StatusType.enRetard,
      'partiel': StatusType.loue,
      'paye': StatusType.disponible,
    };
    final statut = inv['statut'] as String? ?? 'non_paye';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inv['numero_facture'] ?? '',
                  style: GoogleFonts.montserrat(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              StatusBadge(
                label: statutLabels[statut] ?? statut,
                type: statutTypes[statut] ?? StatusType.enRetard,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(inv['client_nom'] ?? '',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(inv['date_emission'] ?? '',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12)),
              Text(
                _formatMoney(
                    (inv['montant_total'] as num?)?.toDouble() ?? 0),
                style: GoogleFonts.montserrat(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          if (statut == 'partiel') ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: ((inv['montant_paye'] as num?)?.toDouble() ?? 0) /
                  ((inv['montant_total'] as num?)?.toDouble() ?? 1),
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }

  // ───────── Dépenses ─────────
  Widget _buildExpensesTab(FinanceState state) {
    if (state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.money_off_rounded,
                size: 64, color: AppColors.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucune dépense',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(financeProvider.notifier).loadExpenses(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.expenses.length,
        itemBuilder: (context, index) {
          final exp = state.expenses[index];
          final catIcons = {
            'materiel': Icons.camera_alt_rounded,
            'deplacement': Icons.directions_car_rounded,
            'location_local': Icons.store_rounded,
            'salaire': Icons.payments_rounded,
            'marketing': Icons.campaign_rounded,
            'autre': Icons.receipt_rounded,
          };
          final cat = exp['categorie'] as String? ?? 'autre';

          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: 50 * (index % 10)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(catIcons[cat] ?? Icons.receipt_rounded,
                        color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exp['description'] ?? '',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(exp['date_depense'] ?? '',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '-${_formatMoney((exp['montant'] as num?)?.toDouble() ?? 0)}',
                    style: GoogleFonts.montserrat(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────── Résumé ─────────
  Widget _buildSummaryTab(FinanceState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 400),
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
                  Text('Résumé du mois',
                      style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold)),
                  const SizedBox(height: 20),
                  _buildSummaryRow(
                      'Chiffre d\'affaires', state.caMois, AppColors.success),
                  const Divider(color: AppColors.surfaceLight, height: 20),
                  _buildSummaryRow(
                      'Dépenses', state.depensesMois, AppColors.error),
                  const Divider(color: AppColors.gold, height: 24),
                  _buildSummaryRow(
                    'Bénéfice net',
                    state.beneficeMois,
                    state.beneficeMois >= 0
                        ? AppColors.success
                        : AppColors.error,
                    isBold: true,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceLight),
                  const SizedBox(height: 12),
                  _buildSummaryInfo(
                    'Factures en attente',
                    '${state.facturesEnAttente}',
                    _formatMoney(state.montantEnAttente),
                  ),
                  _buildSummaryInfo(
                    'Total factures',
                    '${state.dashboard['total_factures'] ?? 0}',
                    '${state.dashboard['total_payees'] ?? 0} payées',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              color: isBold ? color : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            )),
        Text(
          _formatMoney(amount),
          style: GoogleFonts.montserrat(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 20 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryInfo(String label, String value, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          Row(
            children: [
              Text(value,
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('($detail)',
                  style: GoogleFonts.inter(
                      color: AppColors.textHint, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ───────── Dialogs ─────────
  void _showCreateInvoiceDialog() {
    final clientController = TextEditingController();
    final montantController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle facture',
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold)),
              const SizedBox(height: 20),
              StudioTextField(
                controller: clientController,
                labelText: 'Nom du client',
                prefixIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              StudioTextField(
                controller: montantController,
                labelText: 'Montant total (FBu)',
                prefixIcon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              StudioButton(
                label: 'Créer la facture',
                icon: Icons.receipt_rounded,
                width: double.infinity,
                onPressed: () async {
                  if (clientController.text.trim().isEmpty ||
                      montantController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await ref.read(financeProvider.notifier).createInvoice({
                    'client_nom': clientController.text.trim(),
                    'montant_total':
                        double.tryParse(montantController.text) ?? 0,
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateExpenseDialog() {
    final descController = TextEditingController();
    final montantController = TextEditingController();
    String categorie = 'autre';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle dépense',
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold)),
              const SizedBox(height: 20),
              StudioTextField(
                controller: descController,
                labelText: 'Description',
                prefixIcon: Icons.description_rounded,
              ),
              const SizedBox(height: 16),
              StudioTextField(
                controller: montantController,
                labelText: 'Montant (FBu)',
                prefixIcon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(builder: (ctx, setLocal) {
                final catLabels = {
                  'materiel': 'Matériel',
                  'deplacement': 'Déplacement',
                  'location_local': 'Loyer',
                  'salaire': 'Salaire',
                  'marketing': 'Marketing',
                  'autre': 'Autre',
                };
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: catLabels.entries.map((e) {
                    return ChoiceChip(
                      label: Text(e.value),
                      selected: categorie == e.key,
                      onSelected: (s) =>
                          setLocal(() => categorie = e.key),
                      selectedColor: AppColors.yellow,
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: GoogleFonts.inter(
                        color: categorie == e.key
                            ? const Color(0xFF0D0D0D)
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: categorie == e.key
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 20),
              StudioButton(
                label: 'Ajouter la dépense',
                icon: Icons.add_rounded,
                width: double.infinity,
                onPressed: () async {
                  if (descController.text.trim().isEmpty ||
                      montantController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await ref.read(financeProvider.notifier).createExpense({
                    'description': descController.text.trim(),
                    'montant':
                        double.tryParse(montantController.text) ?? 0,
                    'categorie': categorie,
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '${amount.toStringAsFixed(0)} FBu';
  }
}
