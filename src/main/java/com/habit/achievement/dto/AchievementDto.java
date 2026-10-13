package com.habit.achievement.dto;

import com.habit.achievement.Achievement;

public record AchievementDto(String code, String title, int daysRequired, boolean unlocked) {

    public static AchievementDto of(Achievement achievement, long cleanDays) {
        return new AchievementDto(achievement.name(), achievement.getTitle(),
                achievement.getDaysRequired(), cleanDays >= achievement.getDaysRequired());
    }
}
