package com.habit.habit;

import com.habit.achievement.AchievementService;
import com.habit.common.ApiException;
import com.habit.habit.dto.HabitRequest;
import com.habit.habit.dto.HabitResponse;
import com.habit.habit.dto.RelapseRequest;
import com.habit.habit.dto.StatsResponse;
import com.habit.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class HabitService {

    private final HabitRepository habitRepository;
    private final RelapseRepository relapseRepository;
    private final AchievementService achievementService;

    @Transactional(readOnly = true)
    public List<HabitResponse> list(User user) {
        return habitRepository.findByUserIdAndArchivedFalseOrderByCreatedAtDesc(user.getId())
                .stream().map(HabitResponse::from).toList();
    }

    @Transactional
    public HabitResponse create(User user, HabitRequest request) {
        Habit habit = new Habit();
        habit.setUser(user);
        apply(habit, request);
        return HabitResponse.from(habitRepository.save(habit));
    }

    @Transactional
    public HabitResponse update(User user, Long habitId, HabitRequest request) {
        Habit habit = requireOwned(user, habitId);
        apply(habit, request);
        return HabitResponse.from(habitRepository.save(habit));
    }

    /** Мягкое удаление в архив (история срывов и журнал сохраняются). */
    @Transactional
    public void archive(User user, Long habitId) {
        Habit habit = requireOwned(user, habitId);
        habit.setArchived(true);
        habitRepository.save(habit);
    }

    /** Фиксация срыва: счётчик «чистого» времени начнётся заново с этого момента. */
    @Transactional
    public void relapse(User user, Long habitId, RelapseRequest request) {
        Habit habit = requireOwned(user, habitId);
        Relapse relapse = new Relapse();
        relapse.setHabit(habit);
        relapse.setNote(request.note());
        relapseRepository.save(relapse);
    }

    /** Статистика для главного экрана: счётчик, экономия, достижения. */
    @Transactional(readOnly = true)
    public StatsResponse stats(User user, Long habitId) {
        Habit habit = requireOwned(user, habitId);
        Instant baseline = relapseRepository.findTopByHabitIdOrderByHappenedAtDesc(habitId)
                .map(Relapse::getHappenedAt)
                .orElse(habit.getStartDate());
        Duration clean = Duration.between(baseline, Instant.now());
        long cleanDays = clean.toDays();
        BigDecimal savedMoney = habit.getCostPerDay() == null ? null
                : habit.getCostPerDay().multiply(BigDecimal.valueOf(cleanDays)).setScale(2, RoundingMode.HALF_UP);
        long relapseCount = relapseRepository.countByHabitId(habitId);
        return new StatsResponse(habit.getId(), habit.getName(), habit.getStartDate(), baseline,
                cleanDays, clean.getSeconds(), savedMoney, habit.getCurrency(), relapseCount,
                achievementService.buildProgress(cleanDays),
                achievementService.nextAchievement(cleanDays));
    }

    /** Доступ к привычке только владельцу. Public — переиспользуется journal/ai модулями. */
    public Habit requireOwned(User user, Long habitId) {
        Habit habit = habitRepository.findByIdAndArchivedFalse(habitId)
                .orElseThrow(() -> ApiException.notFound("Привычка не найдена"));
        if (!habit.getUser().getId().equals(user.getId())) {
            throw ApiException.forbidden("Нет доступа к этой привычке");
        }
        return habit;
    }

    private void apply(Habit habit, HabitRequest request) {
        habit.setName(request.name().trim());
        habit.setDescription(request.description());
        habit.setCostPerDay(request.costPerDay());
        if (request.currency() != null) {
            habit.setCurrency(request.currency().toUpperCase());
        }
        if (request.startDate() != null) {
            habit.setStartDate(request.startDate());
        }
    }
}
