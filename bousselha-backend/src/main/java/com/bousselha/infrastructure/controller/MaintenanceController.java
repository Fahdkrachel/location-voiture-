package com.bousselha.infrastructure.controller;

import com.bousselha.application.dto.request.MaintenanceRequest;
import com.bousselha.application.dto.response.MaintenanceResponse;
import com.bousselha.application.service.MaintenanceService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/maintenance")
public class MaintenanceController {
    private final MaintenanceService maintenanceService;

    public MaintenanceController(MaintenanceService maintenanceService) {
        this.maintenanceService = maintenanceService;
    }

    @GetMapping
    public List<MaintenanceResponse> findAll() { return maintenanceService.findAll(); }
    @GetMapping("/car/{carId}")
    public List<MaintenanceResponse> findByCarId(@PathVariable Long carId) { return maintenanceService.findByCarId(carId); }
    @PostMapping
    public MaintenanceResponse create(@Valid @RequestBody MaintenanceRequest request) { return maintenanceService.create(request); }
    @PutMapping("/{id}")
    public MaintenanceResponse update(@PathVariable Long id, @Valid @RequestBody MaintenanceRequest request) { return maintenanceService.update(id, request); }

    @PatchMapping("/{id}/complete")
    public MaintenanceResponse complete(@PathVariable Long id) {
        return maintenanceService.complete(id);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        maintenanceService.delete(id);
    }
}
