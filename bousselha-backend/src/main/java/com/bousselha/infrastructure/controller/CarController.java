package com.bousselha.infrastructure.controller;

import com.bousselha.application.dto.request.CarRequest;
import com.bousselha.application.dto.response.CarAvailabilityResponse;
import com.bousselha.application.dto.response.CarHistoryItemResponse;
import com.bousselha.application.dto.response.CarResponse;
import com.bousselha.application.service.CarService;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.FuelType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;

import java.util.List;

@RestController
@RequestMapping("/api/cars")
public class CarController {
    private final CarService carService;

    public CarController(CarService carService) {
        this.carService = carService;
    }

    @GetMapping
    public List<CarResponse> findAll() { return carService.findAll(); }
    @GetMapping("/availability")
    public List<CarAvailabilityResponse> availability(@RequestParam java.time.LocalDate date) {
        return carService.availabilityOnDate(date);
    }
    @GetMapping("/availability/available")
    public List<CarAvailabilityResponse> availableOnDate(@RequestParam LocalDate date) {
        return carService.availableOnDate(date);
    }
    @GetMapping("/available")
    public List<CarResponse> available() { return carService.findByStatus(CarStatus.AVAILABLE); }
    @GetMapping("/rented")
    public List<CarResponse> rented() { return carService.findByStatus(CarStatus.RENTED); }
    @GetMapping("/maintenance")
    public List<CarResponse> maintenance() { return carService.findByStatus(CarStatus.MAINTENANCE); }
    @GetMapping("/{id}")
    public CarResponse findById(@PathVariable Long id) { return carService.findById(id); }
    @PostMapping
    public CarResponse create(
            @RequestParam String brand,
            @RequestParam FuelType fuelType,
            @RequestParam String matricule,
            @RequestParam(required = false) String nextInspectionDate,
            @RequestParam(required = false) String lastOilChangeDate,
            @RequestParam(required = false) String insuranceExpiryDate,
            @RequestParam(required = false) CarStatus status,
            @RequestParam(required = false) MultipartFile image
    ) {
        CarRequest request = new CarRequest(
                brand,
                fuelType,
                matricule,
                parseLocalDate(nextInspectionDate),
                parseLocalDate(lastOilChangeDate),
                parseLocalDate(insuranceExpiryDate),
                null,
                status
        );
        return carService.create(request, image);
    }

    @PutMapping("/{id}")
    public CarResponse update(
            @PathVariable Long id,
            @RequestParam String brand,
            @RequestParam FuelType fuelType,
            @RequestParam String matricule,
            @RequestParam(required = false) String nextInspectionDate,
            @RequestParam(required = false) String lastOilChangeDate,
            @RequestParam(required = false) String insuranceExpiryDate,
            @RequestParam(required = false) CarStatus status,
            @RequestParam(required = false) MultipartFile image
    ) {
        CarRequest request = new CarRequest(
                brand,
                fuelType,
                matricule,
                parseLocalDate(nextInspectionDate),
                parseLocalDate(lastOilChangeDate),
                parseLocalDate(insuranceExpiryDate),
                null,
                status
        );
        return carService.update(id, request, image);
    }

    @PatchMapping("/{id}/available")
    public CarResponse markAvailable(@PathVariable Long id) {
        return carService.markAvailable(id);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) { carService.delete(id); }

    @GetMapping("/{id}/history")
    public List<CarHistoryItemResponse> history(@PathVariable Long id) { return carService.history(id); }

    private LocalDate parseLocalDate(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return null;
        }
        String cleaned = dateStr.trim();
        try {
            return LocalDate.parse(cleaned, java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        } catch (java.time.format.DateTimeParseException e) {
            try {
                return LocalDate.parse(cleaned, java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));
            } catch (java.time.format.DateTimeParseException ex) {
                try {
                    return LocalDate.parse(cleaned, java.time.format.DateTimeFormatter.ofPattern("d/M/yyyy"));
                } catch (java.time.format.DateTimeParseException ex2) {
                    throw new IllegalArgumentException("Format de date invalide (" + dateStr + "). Utilisez YYYY-MM-DD ou DD-MM-YYYY.");
                }
            }
        }
    }
}
