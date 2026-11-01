package com.library.controller;

import com.library.dto.AuthResponse;
import com.library.dto.LoginRequest;
import com.library.dto.RegisterRequest;
import com.library.entity.AppUser;
import com.library.security.JwtAuthenticationFilter;
import com.library.security.JwtTokenService;
import com.library.service.AuthService;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtTokenService tokenService;
    private final boolean secureCookie;

    public AuthController(
            AuthService authService,
            JwtTokenService tokenService,
            @Value("${app.jwt.cookie-secure:true}") boolean secureCookie) {
        this.authService = authService;
        this.tokenService = tokenService;
        this.secureCookie = secureCookie;
    }

    @GetMapping("/csrf")
    public Map<String, String> csrf(CsrfToken csrfToken) {
        return Map.of("token", csrfToken.getToken());
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AppUser user = authService.register(request);
        return authenticatedResponse(user, HttpStatus.CREATED);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            return authenticatedResponse(authService.login(request.getEmail(), request.getPassword()), HttpStatus.OK);
        } catch (AuthenticationException exception) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout() {
        ResponseCookie cookie = ResponseCookie.from(JwtAuthenticationFilter.COOKIE_NAME, "")
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite("Lax")
                .path("/api")
                .maxAge(Duration.ZERO)
                .build();
        return ResponseEntity.noContent().header(HttpHeaders.SET_COOKIE, cookie.toString()).build();
    }

    @GetMapping("/me")
    public AuthResponse currentUser(@AuthenticationPrincipal AppUser user) {
        return toResponse(user);
    }

    private ResponseEntity<AuthResponse> authenticatedResponse(AppUser user, HttpStatus status) {
        ResponseCookie cookie = ResponseCookie.from(JwtAuthenticationFilter.COOKIE_NAME, tokenService.issueToken(user))
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite("Lax")
                .path("/api")
                .maxAge(Duration.ofSeconds(tokenService.getExpirationSeconds()))
                .build();
        return ResponseEntity.status(status)
                .header(HttpHeaders.SET_COOKIE, cookie.toString())
                .body(toResponse(user));
    }

    private AuthResponse toResponse(AppUser user) {
        AuthResponse response = new AuthResponse();
        response.setUserId(user.getId());
        response.setMemberId(user.getMemberId());
        response.setEmail(user.getEmail());
        response.setUsername(user.getDisplayName());
        List<String> roles = user.getRoles().stream()
                .map(Enum::name)
                .sorted(Comparator.naturalOrder())
                .toList();
        response.setRoles(roles);
        return response;
    }
}