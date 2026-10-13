package com.habit.journal.dto;

import com.habit.journal.JournalEntry;

import java.time.Instant;

public record JournalResponse(Long id, Long habitId, String title, String text,
                              Integer mood, Instant createdAt) {

    public static JournalResponse from(JournalEntry entry) {
        return new JournalResponse(entry.getId(), entry.getHabit().getId(),
                entry.getTitle(), entry.getText(), entry.getMood(), entry.getCreatedAt());
    }
}
