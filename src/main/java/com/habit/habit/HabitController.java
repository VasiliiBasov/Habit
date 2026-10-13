package com.habit.habit;

import com.habit.habit.dto.HabitRequest;
import com.habit.habit.dto.HabitResponse;
import com.habit.habit.dto.RelapseRequest;
import com.habit.habit.dto.StatsResponse;
import com.habit.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/habits")
@RequiredArgsConstructor
public class HabitController {

    private final HabitService habitService;

    @GetMapping
    public List<HabitResponse> list(@AuthenticationPrincipal User user) {
        return habitService.list(user);
    }

    @PostMapping
    public ResponseEntity<HabitResponse> create(@AuthenticationPrincipal User user,
                                                @Valid @RequestBody HabitRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(habitService.create(user, request));
    }

    @PutMapping("/{id}")
    public HabitResponse update(@AuthenticationPrincipal User user, @PathVariable Long id,
                                @Valid @RequestBody HabitRequest request) {
        return habitService.update(user, id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> archive(@AuthenticationPrincipal User user, @PathVariable Long id) {
        habitService.archive(user, id);
        return ResponseEntity.noContent().build();
    }

    /** Кнопка «Срыв» на главном экране. */
    @PostMapping("/{id}/relapse")
    public ResponseEntity<Void> relapse(@AuthenticationPrincipal User user, @PathVariable Long id,
                                        @Valid @RequestBody(required = false) RelapseRequest request) {
        habitService.relapse(user, id, request == null ? new RelapseRequest(null) : request);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/stats")
    public StatsResponse stats(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return habitService.stats(user, id);
    }
}
