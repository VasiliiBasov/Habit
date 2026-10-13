package com.habit.habit.dto;

import com.habit.habit.Habit;

import java.math.BigDecimal;
import java.time.Instant;

public record HabitResponse(Long id, String name, String description,
                            BigDecimal costPerDay, String currency,
                            Instant startDate, Instant createdAt) {

    public static HabitResponse from(Habit habit) {
        return new HabitResponse(habit.getId(), habit.getName(), habit.getDescription(),
                habit.getCostPerDay(), habit.getCurrency(), habit.getStartDate(), habit.getCreatedAt());
    }
}
