package com.bousselha.application.dto.response;

import java.time.LocalDate;

public record ClientResponse(
        Long id,
        String fullName,
        LocalDate birthDate,
        String addressMorocco,
        String addressAbroad,
        String profession,
        String drivingLicenseNumber,
        String drivingLicenseIssuedAt,
        String cinNumber,
        String passportNumber,
        LocalDate passportIssuedAt,
        String phone,

        String additionalDriverFullName,
        String additionalDriverDrivingLicenseNumber,
        LocalDate additionalDriverDrivingLicenseIssuedAt,
        String additionalDriverPassportNumber
) {
}
