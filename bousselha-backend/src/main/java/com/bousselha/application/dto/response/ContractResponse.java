package com.bousselha.application.dto.response;

import com.bousselha.domain.enums.ContractStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record ContractResponse(
        Long id,
        Long carId,
        String carLabel,
        Long clientId,
        String clientName,
        LocalDateTime departureDatetime,
        LocalDateTime expectedReturnDatetime,
        LocalDateTime actualReturnDatetime,
        BigDecimal totalGeneral,
        ContractStatus status
) {
}
