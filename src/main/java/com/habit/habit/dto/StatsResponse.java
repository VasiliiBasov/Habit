package com.habit.habit.dto;

import com.habit.achievement.dto.AchievementDto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Статистика по привычке для главного экрана.
 *
 * @param currentStreakSince момент, от которого идёт текущий отсчёт (последний срыв или startDate)
 * @param cleanSeconds       для живого счётчика дней/часов/минут/секунд на клиенте
 * @param savedMoney         null, если costPerDay не задан
 * @param nextAchievement    null, если открыты все достижения
 */
public record StatsResponse(Long habitId, String habitName,
                            Instant startDate, Instant currentStreakSince,
                            long cleanDays, long cleanSeconds,
                            BigDecimal savedMoney, String currency,
                            long relapseCount,
                            List<AchievementDto> achievements,
                            AchievementDto nextAchievement) {
}
