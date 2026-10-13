package com.habit.journal;

import com.habit.common.ApiException;
import com.habit.habit.Habit;
import com.habit.habit.HabitService;
import com.habit.journal.dto.JournalRequest;
import com.habit.journal.dto.JournalResponse;
import com.habit.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class JournalService {

    private final JournalRepository journalRepository;
    private final HabitService habitService;

    @Transactional(readOnly = true)
    public List<JournalResponse> list(User user, Long habitId) {
        habitService.requireOwned(user, habitId);
        return journalRepository.findByHabitIdOrderByCreatedAtDesc(habitId)
                .stream().map(JournalResponse::from).toList();
    }

    @Transactional
    public JournalResponse create(User user, Long habitId, JournalRequest request) {
        Habit habit = habitService.requireOwned(user, habitId);
        JournalEntry entry = new JournalEntry();
        entry.setHabit(habit);
        entry.setTitle(request.title());
        entry.setText(request.text());
        entry.setMood(request.mood());
        return JournalResponse.from(journalRepository.save(entry));
    }

    @Transactional
    public void delete(User user, Long entryId) {
        JournalEntry entry = journalRepository.findById(entryId)
                .orElseThrow(() -> ApiException.notFound("Запись не найдена"));
        if (!entry.getHabit().getUser().getId().equals(user.getId())) {
            throw ApiException.forbidden("Нет доступа к этой записи");
        }
        journalRepository.delete(entry);
    }
}
