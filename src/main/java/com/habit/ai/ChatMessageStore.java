package com.habit.ai;

import com.habit.habit.Habit;
import com.habit.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Транзакционная работа с историей чата.
 * Вынесено из AssistantService: сохранение ответа ассистента происходит
 * асинхронно в reactor-потоке после завершения HTTP-метода,
 * self-invocation @Transactional там бы не сработал.
 */
@Service
@RequiredArgsConstructor
public class ChatMessageStore {

    private final ChatMessageRepository repository;

    @Transactional
    public void save(User user, Habit habit, MessageRole role, String content) {
        ChatMessage message = new ChatMessage();
        message.setUser(user);
        message.setHabit(habit);
        message.setRole(role);
        message.setContent(content);
        repository.save(message);
    }

    /** Последние сообщения в хронологическом порядке (как ждёт LLM). */
    @Transactional(readOnly = true)
    public List<ChatMessage> lastMessages(Long userId) {
        List<ChatMessage> newestFirst = new ArrayList<>(
                repository.findTop20ByUserIdOrderByCreatedAtDesc(userId));
        Collections.reverse(newestFirst);
        return newestFirst;
    }

    @Transactional(readOnly = true)
    public long countUserMessagesSince(Long userId, Instant from) {
        return repository.countByUserIdAndRoleAndCreatedAtGreaterThanEqual(userId, MessageRole.USER, from);
    }
}
