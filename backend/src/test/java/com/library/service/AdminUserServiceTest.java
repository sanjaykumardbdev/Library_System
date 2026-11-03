package com.library.service;

import com.library.dto.AdminUserUpdateRequest;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class AdminUserServiceTest {

    private JdbcTemplate jdbcTemplate;
    private AdminUserService adminUserService;

    @BeforeEach
    void setUp() {
        JdbcDataSource dataSource = new JdbcDataSource();
        dataSource.setURL("jdbc:h2:mem:adminusers;MODE=Oracle;DB_CLOSE_DELAY=-1");
        jdbcTemplate = new JdbcTemplate(dataSource);
        jdbcTemplate.execute("DROP ALL OBJECTS");
        jdbcTemplate.execute("CREATE TABLE app_users (user_id BIGINT PRIMARY KEY, username VARCHAR(200), email VARCHAR(200), " +
                "member_id BIGINT, account_status VARCHAR(20))");
        jdbcTemplate.execute("CREATE TABLE app_user_roles (user_id BIGINT, role VARCHAR(30))");
        jdbcTemplate.execute("CREATE TABLE members (member_id BIGINT PRIMARY KEY, full_name VARCHAR(200))");
        jdbcTemplate.execute("CREATE TABLE login_activity (login_id BIGINT PRIMARY KEY, user_id BIGINT, logged_in_at TIMESTAMP)");
        jdbcTemplate.update("INSERT INTO app_users VALUES (1, 'Admin', 'admin@example.test', NULL, 'ACTIVE')");
        jdbcTemplate.update("INSERT INTO app_users VALUES (2, 'Member', 'member@example.test', 20, 'ACTIVE')");
        jdbcTemplate.update("INSERT INTO members VALUES (20, 'Member Name')");
        jdbcTemplate.update("INSERT INTO app_user_roles VALUES (1, 'ADMIN')");
        jdbcTemplate.update("INSERT INTO app_user_roles VALUES (2, 'MEMBER')");
        adminUserService = new AdminUserService(jdbcTemplate);
    }

    @Test
    void adminCanDisableMemberAndUpdateRoles() {
        AdminUserUpdateRequest request = request(Set.of("MEMBER", "ADMIN"), "DISABLED");

        var updated = adminUserService.updateUser(1L, 2L, request);

        assertEquals("DISABLED", updated.getStatus());
        assertEquals(Set.of("MEMBER", "ADMIN"), updated.getRoles());
    }

    @Test
    void lastAdministratorCannotBeDemotedOrDisabled() {
        assertThrows(ResponseStatusException.class,
                () -> adminUserService.updateUser(1L, 1L, request(Set.of("MEMBER"), "ACTIVE")));
    }

    @Test
    void adminCanReviewSuccessfulLoginActivity() {
        jdbcTemplate.update("INSERT INTO login_activity VALUES (100, 2, SYSDATE)");

        var entries = adminUserService.findLoginActivity(100);

        assertEquals(1, entries.size());
        assertEquals("member@example.test", entries.get(0).getEmail());
    }

    private AdminUserUpdateRequest request(Set<String> roles, String status) {
        AdminUserUpdateRequest request = new AdminUserUpdateRequest();
        request.setRoles(roles);
        request.setStatus(status);
        return request;
    }
}
