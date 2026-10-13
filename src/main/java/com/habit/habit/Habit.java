package com.habit.habit;

import com.habit.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/** Отслеживаемая вредная привычка (курение, алкоголь, сахар и т.д.). */
@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "habits")
public class Habit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 500)
    private String description;

    /** Стоимость привычки в день — для расчёта сэкономленных денег. null = экономия не считается. */
    private java.math.BigDecimal costPerDay;

    /** ISO 4217, напр. RUB/USD/EUR. */
    @Column(length = 3)
    private String currency = "RUB";

    /** Момент начала отказа (первая попытка). Дальше отсчёт идёт от последнего срыва. */
    @Column(nullable = false)
    private Instant startDate = Instant.now();

    /** Мягкое удаление: архивные привычки скрыты из API, но история сохраняется. */
    @Column(nullable = false)
    private boolean archived = false;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
