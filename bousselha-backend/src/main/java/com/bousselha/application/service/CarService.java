package com.bousselha.application.service;

import com.bousselha.application.dto.request.CarRequest;
import com.bousselha.application.dto.response.CarHistoryItemResponse;
import com.bousselha.application.dto.response.CarResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Car;
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

    public CarService(CarRepository carRepository, ContractRepository contractRepository, MaintenanceRepository maintenanceRepository) {
        this.carRepository = carRepository;
        this.contractRepository = contractRepository;
        this.maintenanceRepository = maintenanceRepository;
    }

    public List<CarResponse> findAll() {
        return carRepository.findAll().stream().map(this::map).toList();
    }

    public CarResponse findById(Long id) {
        return map(getCar(id));
    }

    public List<CarResponse> findByStatus(CarStatus status) {
        return carRepository.findByStatus(status).stream().map(this::map).toList();
    }

    public CarResponse create(CarRequest request, MultipartFile image) {
        Car car = new Car();
        apply(car, request, image);
        return map(carRepository.save(car));
    }

    public CarResponse update(Long id, CarRequest request, MultipartFile image) {
        Car car = getCar(id);
        apply(car, request, image);
        return map(carRepository.save(car));
    }

    public void delete(Long id) {
        Car car = getCar(id);
        boolean hasActiveContracts = contractRepository.existsByCarIdAndDeletedFalseAndStatus(car.getId(), ContractStatus.ACTIVE);
        if (hasActiveContracts) {
            throw new IllegalArgumentException("Impossible : voiture en location active");
        }
        carRepository.delete(car);
    }

    public List<CarHistoryItemResponse> history(Long carId) {
        getCar(carId);
        List<CarHistoryItemResponse> rentals = contractRepository.findByDeletedFalse().stream()
                .filter(c -> c.getCar().getId().equals(carId))
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

    private void apply(Car car, CarRequest request, MultipartFile image) {
        car.setBrand(request.brand());
        car.setFuelType(request.fuelType());
        car.setMatricule(request.matricule());
        car.setNextInspectionDate(request.nextInspectionDate());
        car.setLastOilChangeDate(request.lastOilChangeDate());
        car.setInsuranceExpiryDate(request.insuranceExpiryDate());
        if (image != null && !image.isEmpty()) {
            car.setImageUrl(storeImage(image));
        }
        car.setStatus(request.status() == null ? CarStatus.AVAILABLE : request.status());
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
                car.getImageUrl(),
                car.getStatus()
        );
    }
}
