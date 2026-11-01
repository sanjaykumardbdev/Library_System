package com.library.service;

import com.library.dto.AdminUserResponse;
import com.library.dto.AdminUserUpdateRequest;
import com.library.dto.LoginActivityResponse;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class AdminUserService {

    private static final Set<String> ALLOWED_ROLES = Set.of("MEMBER", "ADMIN");
    private final JdbcTemplate jdbcTemplate;

    public AdminUserService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional(readOnly = true)
    public List<AdminUserResponse> findUsers() {
        List<AdminUserResponse> users = jdbcTemplate.query(
                "SELECT u.user_id, u.member_id, u.username, u.email, m.full_name AS member_name, u.account_status " +
                        "FROM app_users u LEFT JOIN members m ON m.member_id = u.member_id ORDER BY u.user_id",
                (rs, rowNum) -> mapUser(rs));
        Map<Long, Set<String>> rolesByUser = new HashMap<>();
        jdbcTemplate.query(
                "SELECT user_id, role FROM app_user_roles ORDER BY role",
                rs -> rolesByUser.computeIfAbsent(rs.getLong("user_id"), ignored -> new HashSet<>())
                        .add(rs.getString("role")));
        users.forEach(user -> user.setRoles(rolesByUser.getOrDefault(user.getUserId(), Set.of())));
        return users;
    }

    @Transactional
    public AdminUserResponse updateUser(Long actorId, Long targetId, AdminUserUpdateRequest request) {
        if (targetId == null || targetId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User ID must be positive");
        }
        String status = request.getStatus().toUpperCase(Locale.ROOT);
        if (!"ACTIVE".equals(status) && !"DISABLED".equals(status)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Status must be ACTIVE or DISABLED");
        }
        Set<String> roles = new HashSet<>();
        for (String role : request.getRoles()) {
            String normalized = role.toUpperCase(Locale.ROOT);
            if (!ALLOWED_ROLES.contains(normalized)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Roles may only be MEMBER or ADMIN");
            }
            roles.add(normalized);
        }
        if (roles.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one account role is required");
        }

        String existingStatus = jdbcTemplate.query(
                "SELECT account_status FROM app_users WHERE user_id = ? FOR UPDATE",
                rs -> rs.next() ? rs.getString(1) : null,
                targetId);
        if (existingStatus == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "App user not found");
        }
        Set<String> existingRoles = new HashSet<>(jdbcTemplate.query(
                "SELECT role FROM app_user_roles WHERE user_id = ?",
                (rs, rowNum) -> rs.getString("role"),
                targetId));
        boolean wasActiveAdmin = "ACTIVE".equalsIgnoreCase(existingStatus) && existingRoles.contains("ADMIN");
        boolean remainsActiveAdmin = "ACTIVE".equals(status) && roles.contains("ADMIN");
        if (actorId.equals(targetId) && !remainsActiveAdmin) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "You cannot disable or remove administrator access from your own account");
        }
        if (wasActiveAdmin && !remainsActiveAdmin) {
            Integer otherActiveAdmins = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM app_users u JOIN app_user_roles r ON r.user_id = u.user_id " +
                            "WHERE u.account_status = 'ACTIVE' AND r.role = 'ADMIN' AND u.user_id <> ?",
                    Integer.class,
                    targetId);
            if (otherActiveAdmins == null || otherActiveAdmins == 0) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "The last active administrator cannot be disabled or demoted");
            }
        }

        jdbcTemplate.update("UPDATE app_users SET account_status = ? WHERE user_id = ?", status, targetId);
        jdbcTemplate.update("DELETE FROM app_user_roles WHERE user_id = ?", targetId);
        for (String role : roles) {
            jdbcTemplate.update("INSERT INTO app_user_roles (user_id, role) VALUES (?, ?)", targetId, role);
        }
        return findUsers().stream()
                .filter(user -> user.getUserId().equals(targetId))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "App user not found"));
    }

    @Transactional(readOnly = true)
    public List<LoginActivityResponse> findLoginActivity(int requestedLimit) {
        int limit = Math.max(1, Math.min(requestedLimit, 500));
        return jdbcTemplate.query(
                "SELECT login_id, user_id, username, email, logged_in_at FROM (" +
                        "SELECT la.login_id, u.user_id, u.username, u.email, la.logged_in_at " +
                        "FROM login_activity la JOIN app_users u ON u.user_id = la.user_id " +
                        "ORDER BY la.logged_in_at DESC, la.login_id DESC) WHERE ROWNUM <= ?",
                (rs, rowNum) -> mapActivity(rs),
                limit);
    }

    private AdminUserResponse mapUser(ResultSet rs) throws SQLException {
        AdminUserResponse response = new AdminUserResponse();
        response.setUserId(rs.getLong("user_id"));
        response.setMemberId((Long) rs.getObject("member_id"));
        response.setUsername(rs.getString("username"));
        response.setEmail(rs.getString("email"));
        response.setMemberName(rs.getString("member_name"));
        response.setStatus(rs.getString("account_status"));
        return response;
    }

    private LoginActivityResponse mapActivity(ResultSet rs) throws SQLException {
        LoginActivityResponse response = new LoginActivityResponse();
        response.setLoginId(rs.getLong("login_id"));
        response.setUserId(rs.getLong("user_id"));
        response.setUsername(rs.getString("username"));
        response.setEmail(rs.getString("email"));
        response.setLoggedInAt(toInstant(rs.getTimestamp("logged_in_at")));
        return response;
    }

    private Instant toInstant(java.sql.Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant();
    }
}
