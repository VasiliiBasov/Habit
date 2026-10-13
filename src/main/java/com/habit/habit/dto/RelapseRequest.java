package com.habit.habit.dto;

import jakarta.validation.constraints.Size;

public record RelapseRequest(@Size(max = 1000) String note) {
}
