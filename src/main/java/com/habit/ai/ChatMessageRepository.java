package com.habit.ai;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    List<ChatMessage> findTop20ByUserIdOrderByCreatedAtDesc(Long userId);

    long countByUserIdAndRoleAndCreatedAtGreaterThanEqual(Long userId, MessageRole role, Instant from);
}
