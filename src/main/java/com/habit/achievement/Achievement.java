package com.habit.achievement;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Каталог достижений — статический, пороги по «чистым» дням.
 * Достижения вычисляются на лету из длительности стрика, хранить их в БД не нужно:
 * они детерминированы и не могут «рассинхронизироваться».
 */
@Getter
@RequiredArgsConstructor
public enum Achievement {

    FIRST_DAY(1, "Первый день"),
    THREE_DAYS(3, "Три дня"),
    WEEK(7, "Неделя"),
    TWO_WEEKS(14, "Две недели"),
    MONTH(30, "Месяц"),
    NINETY_DAYS(90, "90 дней"),
    HALF_YEAR(180, "Полгода"),
    YEAR(365, "Год без привычки");

    private final int daysRequired;
    private final String title;
}
