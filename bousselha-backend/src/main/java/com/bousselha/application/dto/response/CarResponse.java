package com.bousselha.application.dto.response;

import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.FuelType;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record CarResponse(
        Long id,
        String brand,
        FuelType fuelType,
        String matricule,
        LocalDate nextInspectionDate,
        LocalDate lastOilChangeDate,
        LocalDate insuranceExpiryDate,
        Long mileage,
        LocalDateTime mileageUpdatedAt,
        String imageUrl,
        CarStatus status
) {
}
