package com.habit.user.dto;

import com.habit.user.User;

import java.time.Instant;

public record UserDto(Long id, String email, String name, boolean premium, Instant createdAt) {

    public static UserDto from(User user) {
        return new UserDto(user.getId(), user.getEmail(), user.getName(), user.isPremium(), user.getCreatedAt());
    }
}
