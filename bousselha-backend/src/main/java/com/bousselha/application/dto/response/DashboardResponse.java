package com.bousselha.application.dto.response;

public record DashboardResponse(
        long totalCars,
        long available,
        long rented,
        long maintenance
) {
}
