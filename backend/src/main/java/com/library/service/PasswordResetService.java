package com.library.service;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Locale;

@Service
public class PasswordResetService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;
    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final String frontendUrl;
    private final String mailFrom;

    public PasswordResetService(
            JdbcTemplate jdbcTemplate,
            PasswordEncoder passwordEncoder,
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.frontend-url:http://localhost:3000}") String frontendUrl,
            @Value("${app.mail.from:}") String mailFrom) {
        this.jdbcTemplate = jdbcTemplate;
        this.passwordEncoder = passwordEncoder;
        this.mailSenderProvider = mailSenderProvider;
        this.frontendUrl = frontendUrl;
        this.mailFrom = mailFrom;
    }

    @Transactional
    public void requestReset(String email) {
        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null || mailFrom.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Password reset email is not configured. Contact the library administrator.");
        }

        String normalizedEmail = email.trim().toLowerCase(Locale.ROOT);
        Long userId = jdbcTemplate.query(
                "SELECT user_id FROM app_users WHERE LOWER(email) = ? AND account_status = 'ACTIVE'",
                rs -> rs.next() ? rs.getLong("user_id") : null,
                normalizedEmail);
        if (userId == null) {
            return;
        }

        byte[] tokenBytes = new byte[32];
        SECURE_RANDOM.nextBytes(tokenBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
        jdbcTemplate.update(
                "UPDATE password_reset_tokens SET used_at = SYSDATE WHERE user_id = ? AND used_at IS NULL",
                userId);
        jdbcTemplate.update(
                "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at, created_at) " +
                        "VALUES (?, ?, SYSDATE + (1 / 24), SYSDATE)",
                userId,
                hashToken(token));

        String resetUrl = frontendUrl.replaceAll("/+$", "") + "/#/reset-password?token=" + token;
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(mailFrom);
        message.setTo(normalizedEmail);
        message.setSubject("Reset your Library System password");
        message.setText("Use this one-time link within 60 minutes to reset your password:\n\n" +
                resetUrl + "\n\nIf you did not request this, you can ignore this message.");
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Could not send the password reset email. Please try again later.");
        }
    }

    @Transactional
    public void resetPassword(String token, String newPassword) {
        if (newPassword.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must be at most 72 UTF-8 bytes");
        }
        Long userId = jdbcTemplate.query(
                "SELECT user_id FROM password_reset_tokens " +
                        "WHERE token_hash = ? AND used_at IS NULL AND expires_at > SYSDATE FOR UPDATE",
                rs -> rs.next() ? rs.getLong("user_id") : null,
                hashToken(token));
        if (userId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This password reset link is invalid or expired.");
        }

        int updated = jdbcTemplate.update(
                "UPDATE app_users SET password_hash = ?, password_version = password_version + 1, " +
                        "must_change_password = 0 WHERE user_id = ? AND account_status = 'ACTIVE'",
                passwordEncoder.encode(newPassword),
                userId);
        if (updated != 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This password reset link is invalid or expired.");
        }
        jdbcTemplate.update(
                "UPDATE password_reset_tokens SET used_at = SYSDATE WHERE user_id = ? AND used_at IS NULL",
                userId);
    }

    private String hashToken(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}
