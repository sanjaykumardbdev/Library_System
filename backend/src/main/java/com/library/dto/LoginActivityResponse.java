package com.library.dto;

import java.time.Instant;

public class LoginActivityResponse {
    private Long loginId;
    private Long userId;
    private String username;
    private String email;
    private Instant loggedInAt;

    public Long getLoginId() { return loginId; }
    public void setLoginId(Long loginId) { this.loginId = loginId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public Instant getLoggedInAt() { return loggedInAt; }
    public void setLoggedInAt(Instant loggedInAt) { this.loggedInAt = loggedInAt; }
}
