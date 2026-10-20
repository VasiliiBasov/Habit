import 'package:flutter_test/flutter_test.dart';
import 'package:habit_app/features/habits/data/habit_models.dart';

/// Снимок реального ответа GET /api/habits/1/stats (smoke-тест 12.10.2026).
/// Защищает модель от рассинхронизации полей с бэкендом.
const liveStatsJson = {
  'habitId': 1,
  'habitName': 'Сигареты',
  'startDate': '2026-10-12T18:16:24.867417Z',
  'currentStreakSince': '2026-10-12T18:16:24.867417Z',
  'cleanDays': 0,
  'cleanSeconds': 0,
  'savedMoney': 0.0,
  'currency': 'RUB',
  'relapseCount': 0,
  'achievements': [
    {'code': 'FIRST_DAY', 'title': 'Первый день', 'daysRequired': 1, 'unlocked': false},
    {'code': 'WEEK', 'title': 'Неделя', 'daysRequired': 7, 'unlocked': false},
  ],
  'nextAchievement': {'code': 'FIRST_DAY', 'title': 'Первый день', 'daysRequired': 1, 'unlocked': false},
};

void main() {
  test('StatsModel парсит живой ответ бэкенда без падений', () {
    final stats = StatsModel.fromJson(liveStatsJson);

    expect(stats.cleanSeconds, 0);
    expect(stats.currency, 'RUB');
    expect(stats.achievements, hasLength(2));
    expect(stats.achievements.first.key, 'FIRST_DAY');
    expect(stats.achievements.first.thresholdSeconds, 86400);

    final next = stats.nextAchievement!;
    expect(next.title, 'Первый день');
    expect(next.secondsToUnlock, 86400); // 1 день при 0 чистых секунд
    expect(next.description, isNotEmpty);
  });

  test('Остаток до следующего достижения не бывает отрицательным', () {
    final json = {
      ...liveStatsJson,
      'cleanSeconds': 2 * 86400, // дальше первого порога
    };
    final stats = StatsModel.fromJson(json);
    expect(stats.nextAchievement!.secondsToUnlock, 0);
  });
}
