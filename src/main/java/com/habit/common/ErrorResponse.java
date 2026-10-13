package com.habit.common;

import java.time.Instant;

/** Унифицированное тело ошибки API. */
public record ErrorResponse(String error, String message, Instant timestamp) {

    public static ErrorResponse of(String error, String message) {
        return new ErrorResponse(error, message, Instant.now());
    }
}
