package com.habit.ai;

import com.habit.ai.dto.ChatMessageDto;
import com.habit.ai.dto.ChatRequest;
import com.habit.ai.dto.LimitResponse;
import com.habit.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AssistantController {

    private final AssistantService assistantService;

    /**
     * Стриминг чата с ИИ (Server-Sent Events).
     * Flutter-клиент читает поток через http.Client / flutter_client_sse — dio потоковый парсинг.
     */
    @PostMapping(path = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter chat(@AuthenticationPrincipal User user, @Valid @RequestBody ChatRequest request) {
        return assistantService.chat(user, request);
    }

    @GetMapping("/history")
    public List<ChatMessageDto> history(@AuthenticationPrincipal User user) {
        return assistantService.history(user);
    }

    /** Freemium-остаток: бейдж «Осталось: N» в шапке чата. Премиум → 404. */
    @GetMapping("/limit")
    public LimitResponse limit(@AuthenticationPrincipal User user) {
        return assistantService.limitInfo(user);
    }
}
