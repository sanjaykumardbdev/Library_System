package com.library.service;

import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PasswordResetServiceTest {

    private JdbcTemplate jdbcTemplate;
    private PasswordEncoder passwordEncoder;
    private PasswordResetService service;

    @BeforeEach
    void setUp() {
        JdbcDataSource dataSource = new JdbcDataSource();
        dataSource.setURL("jdbc:h2:mem:passwordreset;MODE=Oracle;DB_CLOSE_DELAY=-1");
        jdbcTemplate = new JdbcTemplate(dataSource);
        jdbcTemplate.execute("DROP ALL OBJECTS");
        jdbcTemplate.execute("CREATE TABLE password_reset_tokens (user_id BIGINT, token_hash VARCHAR(64), " +
                "expires_at TIMESTAMP, used_at TIMESTAMP, created_at TIMESTAMP)");
        jdbcTemplate.execute("CREATE TABLE app_users (user_id BIGINT PRIMARY KEY, password_hash VARCHAR(100), " +
                "password_version BIGINT DEFAULT 0, account_status VARCHAR(20), " +
                "must_change_password BOOLEAN DEFAULT FALSE)");
        jdbcTemplate.update("INSERT INTO app_users VALUES (7, 'old-hash', 0, 'ACTIVE', TRUE)");
        passwordEncoder = mock(PasswordEncoder.class);
        ObjectProvider<?> provider = mock(ObjectProvider.class);
        @SuppressWarnings("unchecked")
        ObjectProvider<org.springframework.mail.javamail.JavaMailSender> mailProvider =
                (ObjectProvider<org.springframework.mail.javamail.JavaMailSender>) provider;
        service = new PasswordResetService(
                jdbcTemplate, passwordEncoder, mailProvider,
                "http://localhost:3000", "library@example.test");
    }

    @Test
    void resetUsesSingleUseTokenAndInvalidatesPreviouslyIssuedSessions() throws Exception {
        String rawToken = "single-use-test-token";
        String tokenHash = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                .digest(rawToken.getBytes(StandardCharsets.UTF_8)));
        jdbcTemplate.update(
                "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at, created_at) " +
                        "VALUES (7, ?, DATEADD('HOUR', 1, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP)",
                tokenHash);
        when(passwordEncoder.encode("new-secure-password")).thenReturn("$2a$hashed");

        service.resetPassword(rawToken, "new-secure-password");

        assertEquals("$2a$hashed", jdbcTemplate.queryForObject(
                "SELECT password_hash FROM app_users WHERE user_id = 7", String.class));
        assertEquals(1L, jdbcTemplate.queryForObject(
                "SELECT password_version FROM app_users WHERE user_id = 7", Long.class));
        assertEquals(false, jdbcTemplate.queryForObject(
                "SELECT must_change_password FROM app_users WHERE user_id = 7", Boolean.class));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM password_reset_tokens WHERE used_at IS NOT NULL", Integer.class));
        assertThrows(ResponseStatusException.class,
                () -> service.resetPassword(rawToken, "new-secure-password"));
    }
}
