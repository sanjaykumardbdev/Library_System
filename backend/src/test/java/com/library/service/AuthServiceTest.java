package com.library.service;

import com.library.dto.RegisterRequest;
import com.library.entity.AppUser;
import com.library.entity.Role;
import com.library.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private AuthenticationManager authenticationManager;
    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private UserRepository userRepository;
    @InjectMocks private AuthService authService;

    @Test
    void registrationCreatesMemberAndMemberRoleWithHashedPassword() {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("Library Member");
        request.setEmail("  MEMBER@EXAMPLE.TEST ");
        request.setPassword("a-long-test-password");
        request.setMemberType("STUDENT");
        request.setPhone("555-0100");
        when(userRepository.findByEmail("member@example.test")).thenReturn(Optional.empty());
        when(jdbcTemplate.queryForObject("SELECT seq_members.NEXTVAL FROM dual", Long.class)).thenReturn(1001L);
        when(passwordEncoder.encode(request.getPassword())).thenReturn("$2a$hashed");
        when(userRepository.saveAndFlush(any(AppUser.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AppUser created = authService.register(request);

        assertEquals(1001L, created.getMemberId());
        assertEquals("member@example.test", created.getEmail());
        assertEquals("$2a$hashed", created.getPassword());
        assertTrue(created.getRoles().contains(Role.MEMBER));
        verify(jdbcTemplate).update(
                anyString(), eq(1001L), eq("Library Member"), eq("STUDENT"),
                eq("member@example.test"), eq("555-0100"));
        verify(userRepository).saveAndFlush(any(AppUser.class));
    }
}