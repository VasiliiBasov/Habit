package com.habit.subscription;

import com.fasterxml.jackson.databind.JsonNode;
import com.habit.common.ApiException;
import com.habit.user.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Вебхук RevenueCat: единственный источник истины о статусе премиум-подписки.
 * <p>
 * ВАЖНО: во Flutter-клиенте appUserID RevenueCat должен совпадать с email пользователя
 * (Purchases.logIn(email) после логина в приложении), иначе события не смапятся на аккаунт.
 * <p>
 * Endpoint публичный (permitAll в SecurityConfig) — защита только секретом в Authorization
 * (задаётся в RevenueCat Dashboard → Integrations → Webhooks).
 */
@Slf4j
@RestController
@RequestMapping("/api/webhooks")
public class RevenueCatWebhookController {

    private final UserRepository userRepository;
    private final String webhookSecret;

    public RevenueCatWebhookController(UserRepository userRepository,
                                       @Value("${app.revenuecat.webhook-secret}") String webhookSecret) {
        this.userRepository = userRepository;
        this.webhookSecret = webhookSecret;
    }

    @PostMapping("/revenuecat")
    public ResponseEntity<Void> handle(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestBody JsonNode payload) {

        if (webhookSecret == null || webhookSecret.isBlank()) {
            throw ApiException.unavailable("RevenueCat вебхук не настроен (REVENUECAT_WEBHOOK_SECRET)");
        }
        if (!("Bearer " + webhookSecret).equals(authorization)) {
            throw ApiException.forbidden("Неверный секрет вебхука");
        }

        JsonNode event = payload.path("event");
        String type = event.path("type").asText("");
        String appUserId = event.path("app_user_id").asText("");
        log.info("RevenueCat event: type={}, appUserId={}", type, appUserId);

        switch (type) {
            // Доступ открыт (CANCELLATION = отмена автопродления, доступ остаётся до конца периода → не снимаем)
            case "INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE", "UNCANCELLATION", "NON_RENEWING_PURCHASE" ->
                    setPremium(appUserId, true);
            // Доступ закрыт
            case "EXPIRATION", "REFUND" -> setPremium(appUserId, false);
            default -> log.debug("RevenueCat event {} игнорируется", type);
        }
        return ResponseEntity.ok().build();
    }

    private void setPremium(String email, boolean premium) {
        if (email == null || email.isBlank()) {
            return;
        }
        userRepository.findByEmail(email).ifPresentOrElse(user -> {
            if (user.isPremium() != premium) {
                user.setPremium(premium);
                userRepository.save(user);
                log.info("Premium {} для {}", premium ? "включён" : "выключен", email);
            }
        }, () -> log.warn("RevenueCat: пользователь {} не найден", email));
    }
}
