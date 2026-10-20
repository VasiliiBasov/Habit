import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/habits_cubit.dart';

/// Нижний лист создания привычки.
class CreateHabitSheet extends StatefulWidget {
  const CreateHabitSheet({super.key});

  @override
  State<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<CreateHabitSheet> {
  final _name = TextEditingController();
  final _cost = TextEditingController();
  String _currency = 'RUB';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final cost = double.tryParse(_cost.text.replaceAll(',', '.')) ?? 0;
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final ok = await context.read<HabitsCubit>().create(name, cost, _currency);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('От какой привычки избавляемся?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'Курение, сладкое, соцсети…',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Расход в день',
                    hintText: '350',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownMenu<String>(
                initialSelection: _currency,
                onSelected: (v) =>
                    setState(() => _currency = v ?? _currency),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'RUB', label: '₽'),
                  DropdownMenuEntry(value: 'USD', label: '\$'),
                  DropdownMenuEntry(value: 'EUR', label: '€'),
                  DropdownMenuEntry(value: 'KZT', label: '₸'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Сумма нужна, чтобы считать сэкономленные деньги — '
              'это мотивирует лучше календаря.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.check),
            label: Text(_busy ? 'Создаём…' : 'Начинаю отсчёт!'),
          ),
        ],
      ),
    );
  }
}
