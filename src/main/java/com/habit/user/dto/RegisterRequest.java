package com.habit.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Email @Size(max = 255) String email,
        // BCrypt принимает максимум 72 байта пароля
        @NotBlank @Size(min = 6, max = 72) String password,
        @NotBlank @Size(max = 64) String name) {
}
