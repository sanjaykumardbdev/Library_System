package com.library.service;

import com.library.dto.RegisterRequest;
import com.library.entity.AppUser;
import com.library.entity.Role;
import com.library.repository.UserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;
    private final UserRepository userRepository;

    public AuthService(
            AuthenticationManager authenticationManager,
            JdbcTemplate jdbcTemplate,
            PasswordEncoder passwordEncoder,
            UserRepository userRepository) {
        this.authenticationManager = authenticationManager;
        this.jdbcTemplate = jdbcTemplate;
        this.passwordEncoder = passwordEncoder;
        this.userRepository = userRepository;
    }

    @Transactional
    public AppUser register(RegisterRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (userRepository.findByEmail(email).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account with this email already exists");
        }
        if (request.getPassword().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must be at most 72 UTF-8 bytes");
        }

        Long memberId = jdbcTemplate.queryForObject("SELECT seq_members.NEXTVAL FROM dual", Long.class);
        String memberType = request.getMemberType() == null || request.getMemberType().isBlank()
                ? "STUDENT"
                : request.getMemberType().toUpperCase(Locale.ROOT);
        try {
            jdbcTemplate.update(
                "INSERT INTO members (member_id, full_name, member_type, email, phone, join_date, status) " +
                    "VALUES (?, ?, ?, ?, ?, SYSDATE, 'ACTIVE')",
                memberId,
                request.getUsername().trim(),
                memberType,
                email,
                request.getPhone());

            AppUser user = new AppUser();
            user.setUsername(request.getUsername().trim());
            user.setEmail(email);
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            user.setMemberId(memberId);
            user.setStatus("ACTIVE");
            user.getRoles().add(Role.MEMBER);
            return userRepository.saveAndFlush(user);
        } catch (DataIntegrityViolationException exception) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account with this email already exists", exception);
        }
    }

    public AppUser login(String email, String password) {
        try {
            authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(normalizeEmail(email), password));
        } catch (AuthenticationException exception) {
            throw new BadCredentialsException("Invalid email or password");
        }
        AppUser user = userRepository.findByEmail(normalizeEmail(email))
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));
        jdbcTemplate.update(
                "INSERT INTO login_activity (user_id, logged_in_at) VALUES (?, SYSDATE)",
                user.getId());
        return user;
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}