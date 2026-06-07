package com.bousselha.application.dto.request;

import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.FuelType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.time.LocalDate;

public record CarRequest(
        @NotBlank String brand,
        @NotNull FuelType fuelType,
        @NotBlank String matricule,
        LocalDate nextInspectionDate,
        LocalDate lastOilChangeDate,
        LocalDate insuranceExpiryDate,
        @NotNull @PositiveOrZero Long mileage,
        String imageUrl,
        CarStatus status
) {
}
