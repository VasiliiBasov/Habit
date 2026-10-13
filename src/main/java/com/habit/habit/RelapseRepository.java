package com.habit.habit;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RelapseRepository extends JpaRepository<Relapse, Long> {

    Optional<Relapse> findTopByHabitIdOrderByHappenedAtDesc(Long habitId);

    long countByHabitId(Long habitId);

    void deleteByHabitId(Long habitId);
}
