import 'package:flutter/material.dart';

import '../../data/habit_models.dart';

/// Сетка достижений + прогресс до следующего.
class AchievementsCard extends StatelessWidget {
  final StatsModel stats;

  const AchievementsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final next = stats.nextAchievement;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Достижения', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in stats.achievements)
                  Tooltip(
                    message: '${a.title} — ${a.description}',
                    child: Chip(
                      avatar: Icon(
                        a.unlocked ? Icons.emoji_events : Icons.lock_outline,
                        size: 18,
                        color: a.unlocked ? Colors.amberAccent : Colors.grey,
                      ),
                      label: Text(a.title),
                    ),
                  ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 16),
              Text(
                'Следующее: «${next.title}» — ещё ${((next.secondsToUnlock ?? 0) / 3600).ceil()} ч',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: next.thresholdSeconds == 0
                    ? 0
                    : (1 -
                            (next.secondsToUnlock ?? 0) /
                                next.thresholdSeconds)
                        .clamp(0.0, 1.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
