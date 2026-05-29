package com.bousselha.application.dto.response;

import com.bousselha.domain.enums.IncomeSource;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record IncomeRecordResponse(
        Long id,
        BigDecimal amount,
        LocalDateTime recordedAt,
        IncomeSource source,
        String description,
        Long contractId,
        Long clientId,
        String clientName
) {
}
