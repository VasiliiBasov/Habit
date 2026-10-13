package com.habit.ai.dto;

import com.habit.ai.ChatMessage;

import java.time.Instant;

public record ChatMessageDto(Long id, String role, String content, Instant createdAt) {

    public static ChatMessageDto from(ChatMessage message) {
        return new ChatMessageDto(message.getId(), message.getRole().name(),
                message.getContent(), message.getCreatedAt());
    }
}
