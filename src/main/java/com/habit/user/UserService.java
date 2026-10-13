package com.habit.user;

import com.habit.common.ApiException;
import com.habit.security.JwtService;
import com.habit.user.dto.AuthResponse;
import com.habit.user.dto.LoginRequest;
import com.habit.user.dto.RegisterRequest;
import com.habit.user.dto.UserDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalize(request.email());
        if (userRepository.existsByEmail(email)) {
            throw ApiException.conflict("Пользователь с таким email уже зарегистрирован");
        }
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setName(request.name().trim());
        userRepository.save(user);
        return new AuthResponse(jwtService.generateToken(email), UserDto.from(user));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String email = normalize(request.email());
        ApiException invalid = new ApiException(HttpStatus.UNAUTHORIZED, "Неверный email или пароль");
        User user = userRepository.findByEmail(email).orElseThrow(() -> invalid);
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw invalid;
        }
        return new AuthResponse(jwtService.generateToken(email), UserDto.from(user));
    }

    private String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
