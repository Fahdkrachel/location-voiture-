package com.bousselha.application.dto.response;

import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.enums.FuelType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record ContractResponse(
        Long id,
        Long carId,
        String carLabel,
        String carBrand,
        String carMatricule,
        FuelType carFuelType,
        String departurePlace,
        String returnPlace,
        Long clientId,
        String clientName,
        LocalDate clientBirthDate,
        String clientAddressMorocco,
        String clientAddressAbroad,
        String clientProfession,
        String clientDrivingLicenseNumber,
        String clientDrivingLicenseIssuedAt,
        String clientCinNumber,
        String clientPassportNumber,
        LocalDate clientPassportIssuedAt,
        String clientPhone,
        String additionalDriverName,
        String additionalDriverLicense,
        String additionalDriverLicenseIssuedAt,
        String additionalDriverPassport,
        LocalDateTime departureDatetime,
        LocalDateTime expectedReturnDatetime,
        LocalDateTime actualReturnDatetime,
        Integer durationDays,
        BigDecimal pricePerHour,
        BigDecimal pricePerDay,
        BigDecimal pricePerWeek,
        BigDecimal pricePerMonth,
        Boolean withInsurance,
        BigDecimal totalPrice,
        BigDecimal supplement,
        BigDecimal totalGeneral,
        BigDecimal paymentCash,
        BigDecimal paymentCheck,
        BigDecimal paymentDeposit,
        String vehicleConditionDeparture,
        String vehicleConditionReturn,
        String damagesIdentified,
        LocalDateTime createdAt,
        ContractStatus status
) {
}
