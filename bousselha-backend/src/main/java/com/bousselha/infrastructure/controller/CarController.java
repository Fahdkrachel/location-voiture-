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
            @RequestParam(required = false) LocalDate nextInspectionDate,
            @RequestParam(required = false) LocalDate lastOilChangeDate,
            @RequestParam(required = false) LocalDate insuranceExpiryDate,
            @RequestParam(required = false) CarStatus status,
            @RequestParam(required = false) MultipartFile image
    ) {
        CarRequest request = new CarRequest(
                brand,
                fuelType,
                matricule,
                nextInspectionDate,
                lastOilChangeDate,
                insuranceExpiryDate,
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
            @RequestParam(required = false) LocalDate nextInspectionDate,
            @RequestParam(required = false) LocalDate lastOilChangeDate,
            @RequestParam(required = false) LocalDate insuranceExpiryDate,
            @RequestParam(required = false) CarStatus status,
            @RequestParam(required = false) MultipartFile image
    ) {
        CarRequest request = new CarRequest(
                brand,
                fuelType,
                matricule,
                nextInspectionDate,
                lastOilChangeDate,
                insuranceExpiryDate,
                null,
                status
        );
        return carService.update(id, request, image);
    }
    @PatchMapping("/{id}/status")
    public CarResponse updateStatus(
            @PathVariable Long id,
            @RequestParam CarStatus status,
            @RequestParam(defaultValue = "false") boolean force
    ) {
        return carService.updateStatus(id, status, force);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) { carService.delete(id); }
    @GetMapping("/{id}/history")
    public List<CarHistoryItemResponse> history(@PathVariable Long id) { return carService.history(id); }
}
