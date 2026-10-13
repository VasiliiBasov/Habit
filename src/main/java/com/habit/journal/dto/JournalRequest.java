package com.habit.journal.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record JournalRequest(
        @Size(max = 200) String title,
        @NotBlank @Size(max = 4000) String text,
        @Min(1) @Max(5) Integer mood) {
}
