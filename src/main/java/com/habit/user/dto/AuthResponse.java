package com.habit.user.dto;

/** Ответ на регистрацию/логин: JWT + профиль. */
public record AuthResponse(String token, UserDto user) {
}
