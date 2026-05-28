package com.bousselha.application.service;

import com.bousselha.application.dto.response.ContractResponse;
import com.bousselha.application.dto.response.DashboardAlertResponse;
import com.bousselha.application.dto.response.DashboardResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.model.Car;
import com.bousselha.domain.repository.CarRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class DashboardService {
    private static final int INSURANCE_ALERT_DAYS = 30;
    private static final int INSPECTION_ALERT_DAYS = 30;
    private static final int OIL_CHANGE_DELAY_DAYS = 180;

    private final CarRepository carRepository;
    private final ContractService contractService;

    public DashboardService(CarRepository carRepository, ContractService contractService) {
        this.carRepository = carRepository;
        this.contractService = contractService;
    }

    public DashboardResponse stats() {
        return new DashboardResponse(
                carRepository.count(),
                carRepository.findByStatus(CarStatus.AVAILABLE).size(),
                carRepository.findByStatus(CarStatus.RENTED).size(),
                carRepository.findByStatus(CarStatus.MAINTENANCE).size()
        );
    }

    public List<ContractResponse> calendar() {
        return contractService.findActive();
    }

    public List<DashboardAlertResponse> alerts() {
        LocalDate now = LocalDate.now();
        LocalDate insuranceWarningDate = now.plusDays(INSURANCE_ALERT_DAYS);
        LocalDate inspectionWarningDate = now.plusDays(INSPECTION_ALERT_DAYS);
        LocalDate oilDelayLimit = now.minusDays(OIL_CHANGE_DELAY_DAYS);

        List<DashboardAlertResponse> alerts = new ArrayList<>();
        for (Car car : carRepository.findAll()) {
            String carLabel = car.getBrand() + " - " + car.getMatricule();

            if (car.getInsuranceExpiryDate() != null && !car.getInsuranceExpiryDate().isAfter(insuranceWarningDate)) {
                String severity = car.getInsuranceExpiryDate().isBefore(now) ? "HIGH" : "MEDIUM";
                alerts.add(new DashboardAlertResponse(
                        "INSURANCE",
                        car.getId(),
                        carLabel,
                        "Assurance expiree ou proche d'expiration",
                        severity,
                        car.getInsuranceExpiryDate()
                ));
            }

            if (car.getNextInspectionDate() != null && !car.getNextInspectionDate().isAfter(inspectionWarningDate)) {
                String severity = car.getNextInspectionDate().isBefore(now) ? "HIGH" : "MEDIUM";
                alerts.add(new DashboardAlertResponse(
                        "INSPECTION",
                        car.getId(),
                        carLabel,
                        "Controle technique proche ou depasse",
                        severity,
                        car.getNextInspectionDate()
                ));
            }

            if (car.getLastOilChangeDate() != null && car.getLastOilChangeDate().isBefore(oilDelayLimit)) {
                alerts.add(new DashboardAlertResponse(
                        "OIL_CHANGE",
                        car.getId(),
                        carLabel,
                        "Vidange en retard",
                        "MEDIUM",
                        car.getLastOilChangeDate()
                ));
            }
        }
        return alerts;
    }
}
