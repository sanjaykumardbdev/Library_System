package com.library.security;

import com.library.entity.AppUser;
import com.library.entity.Role;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JwtTokenServiceTest {

    private static final String SECRET = Base64.getEncoder().encodeToString(
            "library-test-key-at-least-thirty-two-bytes".getBytes(StandardCharsets.UTF_8));

    @Test
    void acceptsTokenForMatchingAccountAndRejectsChangedAccount() {
        JwtTokenService tokenService = new JwtTokenService(SECRET, 60_000);
        AppUser user = user(41L, "member@example.test");
        String token = tokenService.issueToken(user);

        assertTrue(tokenService.isValidFor(token, user));
        assertFalse(tokenService.isValidFor(token, user(42L, "member@example.test")));
        assertFalse(tokenService.isValidFor(token + "tampered", user));
    }

    private AppUser user(Long id, String email) {
        AppUser user = new AppUser();
        user.setId(id);
        user.setEmail(email);
        user.setMemberId(1001L);
        user.getRoles().add(Role.MEMBER);
        return user;
    }
}