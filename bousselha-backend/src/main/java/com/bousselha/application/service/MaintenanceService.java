package com.bousselha.application.service;

import com.bousselha.application.dto.request.MaintenanceRequest;
import com.bousselha.application.dto.response.MaintenanceResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.model.Car;
import com.bousselha.domain.model.Maintenance;
import com.bousselha.domain.repository.CarRepository;
import com.bousselha.domain.repository.MaintenanceRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class MaintenanceService {
    private final MaintenanceRepository maintenanceRepository;
    private final CarRepository carRepository;

    public MaintenanceService(MaintenanceRepository maintenanceRepository, CarRepository carRepository) {
        this.maintenanceRepository = maintenanceRepository;
        this.carRepository = carRepository;
    }

    public List<MaintenanceResponse> findAll() {
        return maintenanceRepository.findAll().stream().map(this::map).toList();
    }

    public List<MaintenanceResponse> findByCarId(Long carId) {
        return maintenanceRepository.findByCarId(carId).stream().map(this::map).toList();
    }

    public MaintenanceResponse create(MaintenanceRequest request) {
        Car car = getCar(request.carId());
        Maintenance maintenance = new Maintenance();
        maintenance.setCar(car);
        apply(maintenance, request);
        car.setStatus(CarStatus.MAINTENANCE);
        return map(maintenanceRepository.save(maintenance));
    }

    public MaintenanceResponse update(Long id, MaintenanceRequest request) {
        Maintenance maintenance = maintenanceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Maintenance not found: " + id));
        Car car = getCar(request.carId());
        maintenance.setCar(car);
        apply(maintenance, request);
        return map(maintenanceRepository.save(maintenance));
    }

    private Car getCar(Long id) {
        return carRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Car not found: " + id));
    }

    private void apply(Maintenance maintenance, MaintenanceRequest request) {
        maintenance.setType(request.type());
        maintenance.setDescription(request.description());
        maintenance.setStartDate(request.startDate());
        maintenance.setEndDate(request.endDate());
        maintenance.setCost(request.cost());
    }

    private MaintenanceResponse map(Maintenance m) {
        return new MaintenanceResponse(
                m.getId(),
                m.getCar().getId(),
                m.getCar().getBrand() + " - " + m.getCar().getMatricule(),
                m.getType(),
                m.getDescription(),
                m.getStartDate(),
                m.getEndDate(),
                m.getCost()
        );
    }
}
