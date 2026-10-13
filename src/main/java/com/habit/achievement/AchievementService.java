package com.habit.achievement;

import com.habit.achievement.dto.AchievementDto;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

@Service
public class AchievementService {

    /** Полный прогресс: все достижения с флагом unlocked. */
    public List<AchievementDto> buildProgress(long cleanDays) {
        return Arrays.stream(Achievement.values())
                .map(a -> AchievementDto.of(a, cleanDays))
                .toList();
    }

    /** Ближайшее неразблокированное достижение (для бара прогресса) или null, если открыты все. */
    public AchievementDto nextAchievement(long cleanDays) {
        return Arrays.stream(Achievement.values())
                .filter(a -> cleanDays < a.getDaysRequired())
                .findFirst()
                .map(a -> AchievementDto.of(a, cleanDays))
                .orElse(null);
    }
}
