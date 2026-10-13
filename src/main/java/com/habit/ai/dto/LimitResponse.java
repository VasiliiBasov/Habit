package com.habit.ai.dto;

/** Остаток freemium-лимита ИИ-сообщений: сколько всего в сутки и сколько уже использовано. */
public record LimitResponse(int limit, long used) {
}
