import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/studio_button.dart';
import '../../../../core/widgets/studio_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/loading_studio.dart';
import '../../providers/team_provider.dart';

/// Page Équipe — Tâches kanban, pointage, membres
class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage>
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
      ref.read(teamProvider.notifier).loadTasks();
      ref.read(teamProvider.notifier).loadMembers();
      ref.read(teamProvider.notifier).loadAttendance();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamProvider);

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
                child: Row(
                  children: [
                    Text(
                      'Équipe',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const Spacer(),
                    // Boutons check-in / check-out
                    _buildCheckInButton(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats rapides
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Row(
                  children: [
                    _buildStatCard('À faire', state.tasksToDo,
                        Icons.pending_actions_rounded, AppColors.warning),
                    const SizedBox(width: 8),
                    _buildStatCard('En cours', state.tasksInProgress,
                        Icons.autorenew_rounded, AppColors.info),
                    const SizedBox(width: 8),
                    _buildStatCard('Terminées', state.tasksDone,
                        Icons.check_circle_rounded, AppColors.success),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tabs
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
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
                  unselectedLabelStyle:
                      GoogleFonts.inter(fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Tâches'),
                    Tab(text: 'Pointage'),
                    Tab(text: 'Membres'),
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
                        _buildTasksTab(state),
                        _buildAttendanceTab(state),
                        _buildMembersTab(state),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.yellow,
              onPressed: () => _showCreateTaskDialog(),
              child: const Icon(Icons.add_rounded, color: Color(0xFF0D0D0D)),
            )
          : null,
    );
  }

  Widget _buildCheckInButton() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final success = await ref.read(teamProvider.notifier).checkIn();
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Check-in enregistré !',
                        style: GoogleFonts.inter()),
                    backgroundColor: AppColors.success),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.login_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 6),
                Text('In',
                    style: GoogleFonts.inter(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final success = await ref.read(teamProvider.notifier).checkOut();
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Check-out enregistré !',
                        style: GoogleFonts.inter()),
                    backgroundColor: AppColors.info),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 6),
                Text('Out',
                    style: GoogleFonts.inter(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text('$count',
                style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ───────── Tab Tâches ─────────
  Widget _buildTasksTab(TeamState state) {
    if (state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded,
                size: 64, color: AppColors.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucune tâche',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(teamProvider.notifier).loadTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.tasks.length,
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: 50 * (index % 10)),
            child: _buildTaskCard(task),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final prioriteColors = {
      'basse': AppColors.textSecondary,
      'normale': AppColors.info,
      'haute': AppColors.warning,
      'urgente': AppColors.error,
    };

    final statutLabels = {
      'a_faire': 'À faire',
      'en_cours': 'En cours',
      'terminee': 'Terminée',
    };
    final statutTypes = {
      'a_faire': StatusType.enRetard,
      'en_cours': StatusType.loue,
      'terminee': StatusType.disponible,
    };

    final status = task['statut'] as String? ?? 'a_faire';
    final priorite = task['priorite'] as String? ?? 'normale';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: prioriteColors[priorite] ?? AppColors.info,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(task['titre'] ?? '',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (task['assignee_nom'] != null) ...[
                Icon(Icons.person_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(task['assignee_nom'],
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
              ],
              if (task['date_echeance'] != null) ...[
                Icon(Icons.event_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(task['date_echeance'],
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        trailing: StatusBadge(
          label: statutLabels[status] ?? status,
          type: statutTypes[status] ?? StatusType.disponible,
        ),
        onTap: () => _showTaskStatusDialog(task),
      ),
    );
  }

  void _showTaskStatusDialog(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task['titre'] ?? '',
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold)),
              const SizedBox(height: 20),
              Text('Changer le statut :',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...['a_faire', 'en_cours', 'terminee'].map((s) {
                final labels = {
                  'a_faire': 'À faire',
                  'en_cours': 'En cours',
                  'terminee': 'Terminée',
                };
                final icons = {
                  'a_faire': Icons.pending_actions_rounded,
                  'en_cours': Icons.autorenew_rounded,
                  'terminee': Icons.check_circle_rounded,
                };
                return ListTile(
                  leading: Icon(icons[s], color: AppColors.gold),
                  title: Text(labels[s] ?? s,
                      style: GoogleFonts.inter(color: AppColors.textPrimary)),
                  selected: task['statut'] == s,
                  selectedTileColor: AppColors.gold.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(teamProvider.notifier)
                        .updateTask(task['id'], {'statut': s});
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showCreateTaskDialog() {
    final titreController = TextEditingController();
    String priorite = 'normale';

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
              Text('Nouvelle tâche',
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold)),
              const SizedBox(height: 20),
              StudioTextField(
                controller: titreController,
                labelText: 'Titre de la tâche',
                prefixIcon: Icons.task_rounded,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(builder: (ctx, setLocal) {
                return Wrap(
                  spacing: 8,
                  children: ['basse', 'normale', 'haute', 'urgente']
                      .map((p) => ChoiceChip(
                            label: Text(p[0].toUpperCase() + p.substring(1)),
                            selected: priorite == p,
                            onSelected: (s) => setLocal(() => priorite = p),
                            selectedColor: AppColors.yellow,
                            backgroundColor: AppColors.surfaceLight,
                            labelStyle: GoogleFonts.inter(
                              color: priorite == p
                                  ? const Color(0xFF0D0D0D)
                                  : AppColors.textSecondary,
                              fontWeight: priorite == p
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ))
                      .toList(),
                );
              }),
              const SizedBox(height: 20),
              StudioButton(
                label: 'Créer',
                icon: Icons.add_rounded,
                width: double.infinity,
                onPressed: () async {
                  if (titreController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await ref.read(teamProvider.notifier).createTask({
                    'titre': titreController.text.trim(),
                    'priorite': priorite,
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────── Tab Pointage ─────────
  Widget _buildAttendanceTab(TeamState state) {
    if (state.attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded,
                size: 64, color: AppColors.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucun pointage enregistré',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(teamProvider.notifier).loadAttendance(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.attendance.length,
        itemBuilder: (context, index) {
          final a = state.attendance[index];
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
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_rounded,
                        color: AppColors.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['user_nom'] ?? 'Membre',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(a['date_pointage'] ?? '',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (a['check_in'] != null)
                        Text(
                          '▶ ${_formatTime(a['check_in'])}',
                          style: GoogleFonts.inter(
                              color: AppColors.success, fontSize: 12),
                        ),
                      if (a['check_out'] != null)
                        Text(
                          '■ ${_formatTime(a['check_out'])}',
                          style: GoogleFonts.inter(
                              color: AppColors.error, fontSize: 12),
                        ),
                      if (a['total_heures'] != null &&
                          (a['total_heures'] as num) > 0)
                        Text(
                          '${(a['total_heures'] as num).toStringAsFixed(1)}h',
                          style: GoogleFonts.montserrat(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  // ───────── Tab Membres ─────────
  Widget _buildMembersTab(TeamState state) {
    if (state.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_rounded,
                size: 64, color: AppColors.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucun membre',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(teamProvider.notifier).loadMembers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.members.length,
        itemBuilder: (context, index) {
          final m = state.members[index];
          final roleColors = {
            'admin': AppColors.yellow,
            'manager': AppColors.gold,
            'photographe': AppColors.info,
            'retoucheur': AppColors.success,
            'assistant': AppColors.textSecondary,
          };
          final role = m['role'] as String? ?? 'photographe';

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        (roleColors[role] ?? AppColors.gold).withValues(alpha: 0.2),
                    child: Text(
                      (m['nom'] as String? ?? '?').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: roleColors[role] ?? AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['nom'] ?? '',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        Text(m['email'] ?? '',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (roleColors[role] ?? AppColors.gold)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role[0].toUpperCase() + role.substring(1),
                      style: GoogleFonts.inter(
                        color: roleColors[role] ?? AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
