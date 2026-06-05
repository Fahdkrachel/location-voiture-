package com.bousselha.application.dto.response;

import java.time.LocalDate;

public record DashboardAlertResponse(
        String type,
        Long carId,
        String carLabel,
        String message,
        String severity,
        LocalDate dueDate,
        Long contractId
) {
}
