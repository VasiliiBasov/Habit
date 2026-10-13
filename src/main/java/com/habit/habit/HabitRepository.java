package com.habit.habit;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface HabitRepository extends JpaRepository<Habit, Long> {

    List<Habit> findByUserIdAndArchivedFalseOrderByCreatedAtDesc(Long userId);

    Optional<Habit> findByIdAndArchivedFalse(Long id);
}
