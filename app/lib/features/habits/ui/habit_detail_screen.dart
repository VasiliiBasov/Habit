import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../journal/ui/journal_tab.dart';
import '../cubit/habit_detail_cubit.dart';
import '../cubit/habits_cubit.dart';
import '../data/habit_models.dart';
import 'widgets/achievements_card.dart';
import 'widgets/timer_card.dart';

/// Экран привычки: прогресс (таймер/деньги/достижения) + журнал.
class HabitDetailScreen extends StatelessWidget {
  final HabitModel habit;

  const HabitDetailScreen({super.key, required this.habit});

  Future<void> _confirmRelapse(BuildContext context) async {
    final cubit = context.read<HabitDetailCubit>();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const RelapseDialog(),
    );
    if (note == null || !context.mounted) return;
    final ok = await cubit.relapse(note: note.isEmpty ? null : note);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Ничего страшного. Начинаем заново — у вас получится.')));
    }
  }

  Future<void> _archive(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('В архив?'),
        content: const Text(
            'Привычка исчезнет из списка. Данные и история срывов сохранятся.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('В архив')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await context.read<HabitsCubit>().archive(habit.id);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(habit.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'В архив',
              onPressed: () => _archive(context),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Прогресс'),
            Tab(text: 'Журнал'),
          ]),
        ),
        body: TabBarView(children: [
          _OverviewTab(habit: habit, onRelapse: () => _confirmRelapse(context)),
          JournalTab(habitId: habit.id),
        ]),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onRelapse;

  const _OverviewTab({required this.habit, required this.onRelapse});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitDetailCubit, HabitDetailState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final stats = state.stats;
        if (state.loading && stats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (stats == null) {
          return const Center(child: Text('Не удалось загрузить статистику'));
        }
        return RefreshIndicator(
          onRefresh: () => context.read<HabitDetailCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TimerCard(
                  habit: habit, stats: stats, fetchedAt: state.fetchedAt!),
              const SizedBox(height: 12),
              MoneyCard(
                  habit: habit, stats: stats, fetchedAt: state.fetchedAt!),
              const SizedBox(height: 12),
              AchievementsCard(stats: stats),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRelapse,
                icon: const Icon(Icons.restart_alt, color: Colors.redAccent),
                label:
                    const Text('Сорвался', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Диалог фиксации срыва с опциональной заметкой о триггере.
class RelapseDialog extends StatefulWidget {
  const RelapseDialog({super.key});

  @override
  State<RelapseDialog> createState() => _RelapseDialogState();
}

class _RelapseDialogState extends State<RelapseDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Зафиксировать срыв'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Счётчик обнулится, но это часть пути. Что стало триггером?'),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Стресс, компания… (необязательно)'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _note.text.trim()),
            child: const Text('Сорвался')),
      ],
    );
  }
}
