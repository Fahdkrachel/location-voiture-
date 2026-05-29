package com.bousselha.application.service;

import com.bousselha.application.dto.request.MaintenanceRequest;
import com.bousselha.application.dto.response.MaintenanceResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.MaintenanceStatus;
import com.bousselha.domain.model.Car;
import com.bousselha.domain.model.Maintenance;
import com.bousselha.domain.repository.CarRepository;
import com.bousselha.domain.repository.MaintenanceRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@Transactional
public class MaintenanceService {
    private final MaintenanceRepository maintenanceRepository;
    private final CarRepository carRepository;
    private final FinancialService financialService;

    public MaintenanceService(
            MaintenanceRepository maintenanceRepository,
            CarRepository carRepository,
            FinancialService financialService
    ) {
        this.maintenanceRepository = maintenanceRepository;
        this.carRepository = carRepository;
        this.financialService = financialService;
    }

    public List<MaintenanceResponse> findAll() {
        reconcileAllCarStatuses();
        return maintenanceRepository.findAll().stream().map(this::map).toList();
    }

    public List<MaintenanceResponse> findByCarId(Long carId) {
        Car car = getCar(carId);
        reconcileCarStatus(car);
        return maintenanceRepository.findByCarId(carId).stream().map(this::map).toList();
    }

    public MaintenanceResponse create(MaintenanceRequest request) {
        Car car = getCar(request.carId());
        Maintenance maintenance = new Maintenance();
        maintenance.setCar(car);
        apply(maintenance, request);
        if (maintenance.getStatus() == null) {
            maintenance.setStatus(MaintenanceStatus.IN_PROGRESS);
        }
        car.setStatus(CarStatus.MAINTENANCE);
        carRepository.save(car);
        Maintenance saved = maintenanceRepository.save(maintenance);
        financialService.recordExpenseFromMaintenance(saved);
        return map(saved);
    }

    public MaintenanceResponse update(Long id, MaintenanceRequest request) {
        Maintenance maintenance = maintenanceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Maintenance not found: " + id));
        Car car = getCar(request.carId());
        maintenance.setCar(car);
        apply(maintenance, request);
        reconcileCarStatus(car);
        carRepository.save(car);
        Maintenance saved = maintenanceRepository.save(maintenance);
        financialService.recordExpenseFromMaintenance(saved);
        return map(saved);
    }

    public boolean hasOngoingMaintenance(Long carId) {
        return maintenanceRepository.findByCarId(carId).stream()
                .anyMatch(this::isOngoing);
    }

    /**
     * Clôture les maintenances encore en cours lorsque l'admin force le véhicule en AVAILABLE.
     */
    public void completeOngoingMaintenancesForCar(Long carId) {
        LocalDate today = LocalDate.now();
        for (Maintenance maintenance : maintenanceRepository.findByCarId(carId)) {
            if (!isOngoing(maintenance)) {
                continue;
            }
            maintenance.setStatus(MaintenanceStatus.COMPLETED);
            if (maintenance.getEndDate() == null || !maintenance.getEndDate().isBefore(today)) {
                maintenance.setEndDate(today);
            }
            maintenanceRepository.save(maintenance);
        }
    }

    /**
     * Met à jour les statuts véhicules selon les maintenances en cours (appelé à la lecture, pas au démarrage).
     */
    public void reconcileAllCarStatuses() {
        for (Car car : carRepository.findAll()) {
            reconcileCarStatus(car);
        }
    }

    void reconcileCarStatus(Car car) {
        if (car.getStatus() == CarStatus.RENTED) {
            return;
        }
        boolean hasOngoing = maintenanceRepository.findByCarId(car.getId()).stream()
                .anyMatch(this::isOngoing);
        if (hasOngoing) {
            if (car.getStatus() != CarStatus.MAINTENANCE) {
                car.setStatus(CarStatus.MAINTENANCE);
                carRepository.save(car);
            }
        } else if (car.getStatus() == CarStatus.MAINTENANCE) {
            car.setStatus(CarStatus.AVAILABLE);
            carRepository.save(car);
        }
    }

    private boolean isOngoing(Maintenance maintenance) {
        if (maintenance.getStatus() == MaintenanceStatus.COMPLETED) {
            return false;
        }
        LocalDate today = LocalDate.now();
        LocalDate end = maintenance.getEndDate();
        if (end != null && end.isBefore(today)) {
            return false;
        }
        return true;
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
        if (request.status() != null) {
            maintenance.setStatus(request.status());
        } else if (maintenance.getStatus() == null) {
            maintenance.setStatus(MaintenanceStatus.IN_PROGRESS);
        }
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
                m.getCost(),
                m.getStatus()
        );
    }
}
