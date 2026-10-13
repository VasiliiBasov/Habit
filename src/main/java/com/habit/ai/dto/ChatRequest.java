package com.habit.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** @param habitId привычка в контексте диалога (null — свободный чат с поддержкой) */
public record ChatRequest(
        @NotBlank @Size(max = 2000) String message,
        Long habitId) {
}
