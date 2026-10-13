package com.habit.habit.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

/** Создание/обновление привычки. startDate null → «сейчас». */
public record HabitRequest(
        @NotBlank @Size(max = 100) String name,
        @Size(max = 500) String description,
        @PositiveOrZero BigDecimal costPerDay,
        @Pattern(regexp = "^[A-Za-z]{3}$", message = "Валюта должна быть кодом ISO 4217, напр. RUB")
        String currency,
        Instant startDate) {
}
