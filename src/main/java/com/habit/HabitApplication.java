package com.habit;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Backend мобильного приложения для отказа от вредных привычек.
 * Модули: security (JWT), user, habit (трекер + срывы + статистика),
 * journal, achievement, ai (ИИ-помощник со стримингом), subscription (RevenueCat).
 */
@SpringBootApplication
public class HabitApplication {

    public static void main(String[] args) {
        SpringApplication.run(HabitApplication.class, args);
    }
}
