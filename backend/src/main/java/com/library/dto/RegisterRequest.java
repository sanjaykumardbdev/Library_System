package com.library.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Size;

public class RegisterRequest {

    @NotBlank
    @Size(max = 200)
    private String username;

    @NotBlank
    @Email
    @Size(max = 200)
    private String email;

    @NotBlank
    @Size(min = 12, max = 72, message = "Password must be between 12 and 72 characters long")
    private String password;

    @Size(max = 30)
    @Pattern(regexp = "STUDENT|PROFESSIONAL", message = "Member type must be STUDENT or PROFESSIONAL")
    private String memberType = "STUDENT";

    @Size(max = 20)
    private String phone;

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getMemberType() {
        return memberType;
    }

    public void setMemberType(String memberType) {
        this.memberType = memberType;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }
}
