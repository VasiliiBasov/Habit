import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/journal_cubit.dart';
import '../data/journal_api.dart';

const _moodEmoji = ['😞', '😕', '😐', '🙂', '😄'];

/// Вкладка «Журнал» на экране привычки.
class JournalTab extends StatelessWidget {
  final int habitId;

  const JournalTab({super.key, required this.habitId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          JournalCubit(ctx.read<JournalApi>(), habitId)..load(),
      child: const _JournalView(),
    );
  }
}

class _JournalView extends StatelessWidget {
  const _JournalView();

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    return BlocConsumer<JournalCubit, JournalState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) => Scaffold(
        body: state.loading && state.entries.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.entries.isEmpty
                ? const Center(
                    child: Text(
                        'Записывайте мысли и триггеры —\nэто помогает увидеть паттерны.',
                        textAlign: TextAlign.center))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = state.entries[i];
                      return Card(
                        child: ListTile(
                          leading: Text(
                              _moodEmoji[e.mood.clamp(1, 5) - 1],
                              style: const TextStyle(fontSize: 24)),
                          title: Text(e.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (e.text != null && e.text!.isNotEmpty)
                                Text(e.text!),
                              Text(dateFmt.format(e.createdAt.toLocal()),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => BlocProvider.value(
              value: context.read<JournalCubit>(),
              child: const _AddEntrySheet(),
            ),
          ),
          child: const Icon(Icons.edit_note),
        ),
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  int _mood = 3;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    setState(() => _busy = true);
    final ok = await context
        .read<JournalCubit>()
        .add(title, _text.text.trim().isEmpty ? null : _text.text.trim(), _mood);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Новая запись', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _mood = i),
                  icon: Opacity(
                    opacity: _mood == i ? 1 : 0.35,
                    child: Text(_moodEmoji[i - 1],
                        style: TextStyle(fontSize: _mood == i ? 32 : 24)),
                  ),
                ),
            ],
          ),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Заголовок', hintText: 'Как прошёл день?'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Текст (необязательно)',
                hintText: 'Что чувствуете? Что стало триггером?'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_busy ? 'Сохраняем…' : 'Добавить'),
          ),
        ],
      ),
    );
  }
}
