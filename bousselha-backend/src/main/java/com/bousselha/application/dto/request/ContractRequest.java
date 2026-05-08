package com.bousselha.application.dto.request;

import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record ContractRequest(
        @NotNull Long carId,
        @NotNull Long clientId,
        String additionalDriverName,
        String additionalDriverLicense,
        String additionalDriverPassport,
        String departurePlace,
        String returnPlace,
        @NotNull LocalDateTime departureDatetime,
        LocalDateTime expectedReturnDatetime,
        Integer durationDays,
        BigDecimal pricePerDay,
        BigDecimal pricePerWeek,
        BigDecimal pricePerMonth,
        BigDecimal pricePerHour,
        Boolean withInsurance,
        BigDecimal totalPrice,
        BigDecimal supplement,
        BigDecimal totalGeneral,
        BigDecimal paymentCash,
        BigDecimal paymentCheck,
        BigDecimal paymentDeposit,
        String vehicleConditionDeparture,
        String vehicleConditionReturn,
        String damagesIdentified
) {
}
