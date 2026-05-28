package com.bousselha.application.dto.request;

import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record ClientRequest(
        @NotBlank String fullName,
        LocalDate birthDate,
        String addressMorocco,
        String addressAbroad,
        String profession,
        String drivingLicenseNumber,
        String drivingLicenseIssuedAt,
        @NotBlank String cinNumber,
        String passportNumber,
        LocalDate passportIssuedAt,
        @NotBlank String phone,

        String additionalDriverFullName,
        String additionalDriverDrivingLicenseNumber,
        LocalDate additionalDriverDrivingLicenseIssuedAt,
        String additionalDriverPassportNumber
) {
}
