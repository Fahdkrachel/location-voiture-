package com.bousselha.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

public record MaintenanceRequest(
        @NotNull Long carId,
        @NotBlank String type,
        String description,
        @NotNull LocalDate startDate,
        LocalDate endDate,
        BigDecimal cost
) {
}
