package com.bousselha.application.dto.response;

import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.FuelType;

public record CarAvailabilityResponse(
        Long carId,
        String brand,
        String matricule,
        FuelType fuelType,
        CarStatus currentStatus,
        String availabilityLabel
) {
}
