import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/habit_models.dart';

String _pluralDays(int days) {
  final mod10 = days % 10;
  final mod100 = days % 100;
  if (mod10 == 1 && mod100 != 11) return 'день';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'дня';
  return 'дней';
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Живой таймер трезвости: тикает каждую секунду от серверного снимка.
class TimerCard extends StatefulWidget {
  final HabitModel habit;
  final StatsModel stats;
  final DateTime fetchedAt;

  const TimerCard({
    super.key,
    required this.habit,
    required this.stats,
    required this.fetchedAt,
  });

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _liveSeconds =>
      widget.stats.cleanSeconds +
      DateTime.now().difference(widget.fetchedAt).inSeconds;

  @override
  Widget build(BuildContext context) {
    final s = _liveSeconds;
    final days = s ~/ 86400;
    final h = (s % 86400) ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Без «${widget.habit.name}» уже',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '$days',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: Colors.tealAccent),
            ),
            Text(_pluralDays(days)),
            const SizedBox(height: 4),
            Text(
              '${_two(h)}:${_two(m)}:${_two(sec)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Срывов за всё время: ${widget.stats.relapseCount}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Сэкономленные деньги — тоже тикают в реальном времени.
class MoneyCard extends StatefulWidget {
  final HabitModel habit;
  final StatsModel stats;
  final DateTime fetchedAt;

  const MoneyCard({
    super.key,
    required this.habit,
    required this.stats,
    required this.fetchedAt,
  });

  @override
  State<MoneyCard> createState() => _MoneyCardState();
}

class _MoneyCardState extends State<MoneyCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveSeconds = widget.stats.cleanSeconds +
        DateTime.now().difference(widget.fetchedAt).inSeconds;
    final liveMoney = widget.habit.costPerDay * liveSeconds / 86400;
    final symbol = currencySymbol(widget.habit.currency);
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: const Icon(Icons.savings_outlined,
            size: 36, color: Colors.amberAccent),
        title: const Text('Сэкономлено за это время'),
        subtitle: Text(
          '${liveMoney.toStringAsFixed(2)} $symbol',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Colors.amberAccent),
        ),
      ),
    );
  }
}
