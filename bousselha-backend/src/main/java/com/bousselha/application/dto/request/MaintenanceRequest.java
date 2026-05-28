package com.bousselha.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import com.bousselha.domain.enums.MaintenanceStatus;

import java.math.BigDecimal;
import java.time.LocalDate;

public record MaintenanceRequest(
        @NotNull Long carId,
        @NotBlank String type,
        String description,
        LocalDate startDate,
        LocalDate endDate,
        @NotNull BigDecimal cost,
        MaintenanceStatus status
) {
}
