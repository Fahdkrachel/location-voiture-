package com.bousselha.application.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateAdminRequest {
    @NotBlank
    private String fullName;

    @Email
    @NotBlank
    private String email;

    private String phone;
}
