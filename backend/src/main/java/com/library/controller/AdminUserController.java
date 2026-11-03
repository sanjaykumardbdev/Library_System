package com.library.controller;

import com.library.dto.AdminUserResponse;
import com.library.dto.AdminUserUpdateRequest;
import com.library.dto.LoginActivityResponse;
import com.library.entity.AppUser;
import com.library.service.AdminUserService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminUserController {

    private final AdminUserService adminUserService;

    public AdminUserController(AdminUserService adminUserService) {
        this.adminUserService = adminUserService;
    }

    @GetMapping("/users")
    public List<AdminUserResponse> users() {
        return adminUserService.findUsers();
    }

    @PatchMapping("/users/{userId}")
    public AdminUserResponse updateUser(
            @PathVariable Long userId,
            @Valid @RequestBody AdminUserUpdateRequest request,
            @AuthenticationPrincipal AppUser actor) {
        return adminUserService.updateUser(actor.getId(), userId, request);
    }

    @GetMapping("/login-activity")
    public List<LoginActivityResponse> loginActivity(
            @RequestParam(defaultValue = "100") int limit) {
        return adminUserService.findLoginActivity(limit);
    }
}
