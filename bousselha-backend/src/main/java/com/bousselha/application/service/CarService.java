package com.bousselha.application.service;

import com.bousselha.application.dto.request.CarRequest;
import com.bousselha.application.dto.response.CarHistoryItemResponse;
import com.bousselha.application.dto.response.CarAvailabilityResponse;
import com.bousselha.application.dto.response.CarResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Car;
import com.bousselha.domain.model.Contract;
import com.bousselha.domain.model.Maintenance;
import com.bousselha.domain.repository.CarRepository;
import com.bousselha.domain.repository.ContractRepository;
import com.bousselha.domain.repository.MaintenanceRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class CarService {
    private static final String UPLOADS_DIR = "src/main/resources/static/uploads/cars";
    private static final String PUBLIC_UPLOADS_PREFIX = "/uploads/cars/";

    private final CarRepository carRepository;
    private final ContractRepository contractRepository;
    private final MaintenanceRepository maintenanceRepository;
    private final MaintenanceService maintenanceService;

    public CarService(
            CarRepository carRepository,
            ContractRepository contractRepository,
            MaintenanceRepository maintenanceRepository,
            MaintenanceService maintenanceService
    ) {
        this.carRepository = carRepository;
        this.contractRepository = contractRepository;
        this.maintenanceRepository = maintenanceRepository;
        this.maintenanceService = maintenanceService;
    }

    public List<CarResponse> findAll() {
        maintenanceService.reconcileAllCarStatuses();
        return carRepository.findAll().stream().map(this::map).toList();
    }

    public CarResponse findById(Long id) {
        Car car = getCar(id);
        maintenanceService.reconcileCarStatus(car);
        return map(car);
    }

    public List<CarResponse> findByStatus(CarStatus status) {
        maintenanceService.reconcileAllCarStatuses();
        return carRepository.findByStatus(status).stream().map(this::map).toList();
    }

    public CarResponse create(CarRequest request, MultipartFile image) {
        Car car = new Car();
        apply(car, request, image, true);
        if (car.getStatus() != CarStatus.AVAILABLE) {
            throw new IllegalArgumentException("NEW_CAR_MUST_BE_AVAILABLE");
        }
        return map(carRepository.save(car));
    }

    public CarResponse update(Long id, CarRequest request, MultipartFile image) {
        Car car = getCar(id);
        CarStatus currentStatus = car.getStatus();
        apply(car, request, image, false);
        car.setStatus(currentStatus);
        return map(carRepository.save(car));
    }

    /**
     * Remise en disponibilité uniquement : depuis LOUÉE ou MAINTENANCE.
     * En maintenance, terminer la maintenance via le module dédié avant.
     */
    public CarResponse markAvailable(Long id) {
        Car car = getCar(id);
        CarStatus current = car.getStatus();
        if (current != CarStatus.RENTED && current != CarStatus.MAINTENANCE) {
            throw new IllegalArgumentException("ONLY_RENTED_OR_MAINTENANCE_CAN_BECOME_AVAILABLE");
        }
        if (current == CarStatus.MAINTENANCE && maintenanceService.hasOngoingMaintenance(id)) {
            throw new IllegalArgumentException("MAINTENANCE_NOT_FINISHED");
        }
        if (current == CarStatus.RENTED) {
            boolean hasOpenContract = contractRepository.existsByCarIdAndDeletedFalseAndStatusIn(
                    car.getId(),
                    java.util.EnumSet.of(ContractStatus.IN_PROGRESS, ContractStatus.ACTIVE)
            );
            if (hasOpenContract) {
                throw new IllegalArgumentException("CAR_HAS_ACTIVE_CONTRACT");
            }
        }
        car.setStatus(CarStatus.AVAILABLE);
        return map(carRepository.save(car));
    }

    public void delete(Long id) {
        Car car = getCar(id);
        boolean hasOpenContracts = contractRepository.existsByCarIdAndDeletedFalseAndStatusIn(
                car.getId(), java.util.EnumSet.of(ContractStatus.IN_PROGRESS, ContractStatus.ACTIVE));
        if (hasOpenContracts) {
            throw new IllegalArgumentException("Impossible : voiture avec contrat en cours");
        }
        carRepository.delete(car);
    }

    public List<CarAvailabilityResponse> availableOnDate(LocalDate date) {
        return availabilityOnDate(date).stream()
                .filter(item -> item.currentStatus() == CarStatus.AVAILABLE)
                .toList();
    }

    public List<CarAvailabilityResponse> availabilityOnDate(LocalDate date) {
        List<Car> cars = carRepository.findAll();
        List<Contract> contracts = contractRepository.findByDeletedFalse();
        List<Maintenance> maintenances = maintenanceRepository.findAll();

        return cars.stream().map(car -> {
            boolean inMaintenance = maintenances.stream()
                    .filter(m -> m.getCar().getId().equals(car.getId()))
                    .anyMatch(m -> maintenanceCoversDate(m, date));

            if (inMaintenance) {
                return new CarAvailabilityResponse(
                        car.getId(), car.getBrand(), car.getMatricule(), car.getFuelType(),
                        CarStatus.MAINTENANCE, "En maintenance", car.getImageUrl()
                );
            }

            boolean rented = contracts.stream()
                    .filter(c -> c.getCar().getId().equals(car.getId()))
                    .filter(c -> c.getStatus() == ContractStatus.IN_PROGRESS || c.getStatus() == ContractStatus.ACTIVE
                            || c.getStatus() == ContractStatus.COMPLETED)
                    .anyMatch(c -> contractCoversDate(c, date));

            if (rented) {
                return new CarAvailabilityResponse(
                        car.getId(), car.getBrand(), car.getMatricule(), car.getFuelType(),
                        CarStatus.RENTED, "Loué", car.getImageUrl()
                );
            }

            return new CarAvailabilityResponse(
                    car.getId(), car.getBrand(), car.getMatricule(), car.getFuelType(),
                    CarStatus.AVAILABLE, "Disponible", car.getImageUrl()
            );
        }).toList();
    }

    private boolean maintenanceCoversDate(Maintenance m, LocalDate date) {
        LocalDate start = m.getStartDate() != null ? m.getStartDate() : LocalDate.MIN;
        LocalDate end = m.getEndDate() != null ? m.getEndDate() : LocalDate.MAX;
        return !date.isBefore(start) && !date.isAfter(end);
    }

    private boolean contractCoversDate(Contract c, LocalDate date) {
        if (c.getDepartureDatetime() == null) return false;
        LocalDate start = c.getDepartureDatetime().toLocalDate();
        LocalDateTime endDt = c.getActualReturnDatetime() != null
                ? c.getActualReturnDatetime()
                : c.getExpectedReturnDatetime();
        if (endDt == null) return !date.isBefore(start);
        LocalDate end = endDt.toLocalDate();
        if (c.getStatus() == ContractStatus.COMPLETED && date.isAfter(end)) {
            return false;
        }
        return !date.isBefore(start) && !date.isAfter(end);
    }

    public List<CarHistoryItemResponse> history(Long carId) {
        getCar(carId);
        List<CarHistoryItemResponse> rentals = contractRepository.findByCarIdForHistory(carId).stream()
                .map(c -> new CarHistoryItemResponse(
                        "RENTAL",
                        c.getClient().getFullName(),
                        c.getDepartureDatetime(),
                        c.getActualReturnDatetime() != null ? c.getActualReturnDatetime() : c.getExpectedReturnDatetime(),
                        c.getTotalGeneral(),
                        c.getStatus().name()
                ))
                .toList();
        List<CarHistoryItemResponse> maintenance = maintenanceRepository.findByCarId(carId).stream()
                .map(m -> new CarHistoryItemResponse(
                        "MAINTENANCE",
                        m.getType(),
                        m.getStartDate().atStartOfDay(),
                        m.getEndDate() == null ? null : m.getEndDate().atStartOfDay(),
                        m.getCost(),
                        "DONE"
                ))
                .toList();
        return java.util.stream.Stream.concat(rentals.stream(), maintenance.stream())
                .sorted((a, b) -> b.startDate().compareTo(a.startDate()))
                .toList();
    }

    private Car getCar(Long id) {
        return carRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Car not found: " + id));
    }

    private void apply(Car car, CarRequest request, MultipartFile image, boolean allowStatusOnCreate) {
        car.setBrand(request.brand());
        car.setFuelType(request.fuelType());
        car.setMatricule(request.matricule());
        car.setNextInspectionDate(request.nextInspectionDate());
        car.setLastOilChangeDate(request.lastOilChangeDate());
        car.setInsuranceExpiryDate(request.insuranceExpiryDate());
        applyMileage(car, request.mileage());
        if (image != null && !image.isEmpty()) {
            car.setImageUrl(storeImage(image));
        }
        if (allowStatusOnCreate) {
            car.setStatus(request.status() == null ? CarStatus.AVAILABLE : request.status());
        }
    }

    private void applyMileage(Car car, Long requestedMileage) {
        if (requestedMileage == null) {
            throw new IllegalArgumentException("MILEAGE_REQUIRED");
        }
        if (requestedMileage < 0) {
            throw new IllegalArgumentException("MILEAGE_MUST_BE_POSITIVE");
        }
        Long currentMileage = car.getMileage() == null ? 0L : car.getMileage();
        if (car.getId() != null && requestedMileage < currentMileage) {
            throw new IllegalArgumentException("MILEAGE_CANNOT_DECREASE");
        }
        if (car.getId() == null || car.getMileage() == null || !requestedMileage.equals(car.getMileage())) {
            car.setMileage(requestedMileage);
            car.setMileageUpdatedAt(LocalDateTime.now());
        }
    }

    private String storeImage(MultipartFile image) {
        String original = Objects.requireNonNullElse(image.getOriginalFilename(), "image.jpg");
        String ext = "";
        int idx = original.lastIndexOf('.');
        if (idx >= 0) ext = original.substring(idx).toLowerCase();
        if (!List.of(".jpg", ".jpeg", ".png").contains(ext)) {
            throw new IllegalArgumentException("Unsupported image format");
        }
        String filename = UUID.randomUUID() + ext;
        try {
            Path dir = Paths.get(UPLOADS_DIR);
            Files.createDirectories(dir);
            Files.copy(image.getInputStream(), dir.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
            return PUBLIC_UPLOADS_PREFIX + filename;
        } catch (IOException e) {
            throw new IllegalArgumentException("Unable to store image: " + e.getMessage());
        }
    }

    private CarResponse map(Car car) {
        return new CarResponse(
                car.getId(),
                car.getBrand(),
                car.getFuelType(),
                car.getMatricule(),
                car.getNextInspectionDate(),
                car.getLastOilChangeDate(),
                car.getInsuranceExpiryDate(),
                car.getMileage(),
                car.getMileageUpdatedAt(),
                car.getImageUrl(),
                car.getStatus()
        );
    }
}
