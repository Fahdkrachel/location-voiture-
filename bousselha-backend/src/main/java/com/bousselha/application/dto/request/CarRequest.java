package com.bousselha.application.dto.request;

import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.FuelType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record CarRequest(
        @NotBlank String brand,
        @NotNull FuelType fuelType,
        @NotBlank String matricule,
        LocalDate nextInspectionDate,
        LocalDate lastOilChangeDate,
        LocalDate insuranceExpiryDate,
        CarStatus status
) {
}
