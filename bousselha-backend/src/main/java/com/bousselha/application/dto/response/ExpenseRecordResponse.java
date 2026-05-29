package com.bousselha.application.dto.response;

import com.bousselha.domain.enums.ExpenseSource;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record ExpenseRecordResponse(
        Long id,
        BigDecimal amount,
        LocalDateTime recordedAt,
        ExpenseSource source,
        String category,
        String description,
        Long maintenanceId,
        String carName
) {
}
