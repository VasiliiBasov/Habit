package com.habit.ai;

import com.habit.ai.dto.ChatMessageDto;
import com.habit.ai.dto.ChatRequest;
import com.habit.ai.dto.LimitResponse;
import com.habit.common.ApiException;
import com.habit.habit.Habit;
import com.habit.habit.HabitService;
import com.habit.habit.dto.StatsResponse;
import com.habit.user.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

/**
 * ИИ-помощник: проксирует запросы к LLM (OpenAI-совместимый API) со стримингом.
 * Ключ API живёт только здесь — мобильный клиент его никогда не видит.
 */
@Slf4j
@Service
public class AssistantService {

    private final ObjectProvider<ChatModel> chatModelProvider;
    private final ChatMessageStore messageStore;
    private final HabitService habitService;
    private final int freeDailyLimit;

    public AssistantService(ObjectProvider<ChatModel> chatModelProvider,
                            ChatMessageStore messageStore,
                            HabitService habitService,
                            @Value("${app.ai.free-daily-limit}") int freeDailyLimit) {
        this.chatModelProvider = chatModelProvider;
        this.messageStore = messageStore;
        this.habitService = habitService;
        this.freeDailyLimit = freeDailyLimit;
    }

    /**
     * Стриминг ответа ассистента через SSE: клиент получает события data: &lt;chunk&gt;.
     * Полный ответ сохраняется в историю по завершении стрима.
     */
    public SseEmitter chat(User user, ChatRequest request) {
        ChatModel chatModel = chatModelProvider.getIfAvailable();
        if (chatModel == null) {
            throw ApiException.unavailable(
                    "ИИ-помощник не настроен: задайте SPRING_AI_MODEL_CHAT=openai и OPENAI_API_KEY");
        }
        enforceDailyLimit(user);

        Habit habit = request.habitId() == null ? null : habitService.requireOwned(user, request.habitId());
        List<Message> messages = buildMessages(user, request, habit);
        messageStore.save(user, habit, MessageRole.USER, request.message());

        SseEmitter emitter = new SseEmitter(180_000L);
        StringBuilder fullAnswer = new StringBuilder();

        ChatClient.create(chatModel).prompt(new Prompt(messages))
                .stream().content()
                .subscribe(
                        chunk -> {
                            fullAnswer.append(chunk);
                            try {
                                emitter.send(SseEmitter.event().data(chunk, MediaType.TEXT_PLAIN));
                            } catch (IOException | IllegalStateException e) {
                                throw new UncheckedIOException(new IOException("Клиент закрыл соединение", e));
                            }
                        },
                        error -> {
                            log.warn("AI streaming failed: {}", error.getMessage());
                            emitter.completeWithError(error);
                        },
                        () -> {
                            messageStore.save(user, habit, MessageRole.ASSISTANT, fullAnswer.toString());
                            emitter.complete();
                        });
        return emitter;
    }

    public List<ChatMessageDto> history(User user) {
        return messageStore.lastMessages(user.getId()).stream().map(ChatMessageDto::from).toList();
    }

    /** Freemium: текущее использование дневного лимита. Премиуму лимит не нужен — 404. */
    public LimitResponse limitInfo(User user) {
        if (user.isPremium()) {
            throw ApiException.notFound("Для премиум-пользователей лимит не действует");
        }
        Instant dayStart = LocalDate.now(ZoneOffset.UTC).atStartOfDay().toInstant(ZoneOffset.UTC);
        long usedToday = messageStore.countUserMessagesSince(user.getId(), dayStart);
        return new LimitResponse(freeDailyLimit, usedToday);
    }

    /** Freemium: бесплатным пользователям — лимит сообщений в сутки, премиум — безлимит. */
    private void enforceDailyLimit(User user) {
        if (user.isPremium()) {
            return;
        }
        Instant dayStart = LocalDate.now(ZoneOffset.UTC).atStartOfDay().toInstant(ZoneOffset.UTC);
        long usedToday = messageStore.countUserMessagesSince(user.getId(), dayStart);
        if (usedToday >= freeDailyLimit) {
            throw ApiException.tooMany("Дневной лимит сообщений исчерпан (" + freeDailyLimit
                    + "). Оформите премиум — общение с помощником станет безлимитным.");
        }
    }

    private List<Message> buildMessages(User user, ChatRequest request, Habit habit) {
        List<Message> messages = new ArrayList<>();
        messages.add(new SystemMessage(systemPrompt(user, habit)));
        for (ChatMessage m : messageStore.lastMessages(user.getId())) {
            messages.add(m.getRole() == MessageRole.USER
                    ? new UserMessage(m.getContent())
                    : new AssistantMessage(m.getContent()));
        }
        messages.add(new UserMessage(request.message()));
        return messages;
    }

    private String systemPrompt(User user, Habit habit) {
        String base = """
                Ты — эмпатичный ИИ-помощник в приложении для отказа от вредных привычек. Твоя роль: \
                поддерживать пользователя, помогать переживать тягу и срывы, давать короткие практичные \
                советы на основе поведенческой психологии (КПТ), мотивировать без осуждения. \
                Пиши по-русски, тепло и по делу, до ~150 слов. Не ставь диагнозы и не заменяешь врача — \
                при признаках тяжёлой зависимости мягко порекомендуй специалиста.
                """;
        StringBuilder context = new StringBuilder(base)
                .append("Имя пользователя: ").append(user.getName()).append('.');
        if (habit != null) {
            StatsResponse stats = habitService.stats(user, habit.getId());
            context.append(" Контекст привычки: «").append(habit.getName())
                    .append("», дней без привычки сейчас: ").append(stats.cleanDays())
                    .append(", всего срывов: ").append(stats.relapseCount()).append('.');
        }
        return context.toString();
    }
}
