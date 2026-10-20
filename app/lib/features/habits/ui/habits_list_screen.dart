import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/habits_cubit.dart';
import '../data/habit_models.dart';
import 'create_habit_sheet.dart';

/// Главная вкладка: список активных привычек.
class HabitsListScreen extends StatelessWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitsCubit, HabitsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Мои привычки')),
        body: state.loading && state.habits.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => context.read<HabitsCubit>().load(),
                child: state.habits.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.spa_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Center(
                              child: Text(
                                  'Пока пусто. Добавьте первую привычку,\nот которой хотите избавиться.',
                                  textAlign: TextAlign.center)),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.habits.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final habit = state.habits[i];
                          return _HabitCard(habit: habit);
                        },
                      ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const CreateHabitSheet(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Новая привычка'),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitModel habit;

  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.flag_outlined)),
        title: Text(habit.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Экономится ${habit.costPerDay.toStringAsFixed(0)} ${currencySymbol(habit.currency)}/день'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/habits/${habit.id}', extra: habit),
      ),
    );
  }
}
