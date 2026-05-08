package com.bousselha.application.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;

public record MaintenanceResponse(
        Long id,
        Long carId,
        String carLabel,
        String type,
        String description,
        LocalDate startDate,
        LocalDate endDate,
        BigDecimal cost
) {
}
