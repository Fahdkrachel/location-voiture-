package com.bousselha.application.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record CarHistoryItemResponse(
        String type,
        String label,
        LocalDateTime startDate,
        LocalDateTime endDate,
        BigDecimal cost,
        String status
) {
}
