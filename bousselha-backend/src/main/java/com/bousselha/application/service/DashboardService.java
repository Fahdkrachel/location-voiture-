package com.bousselha.application.service;

import com.bousselha.application.dto.response.ContractResponse;
import com.bousselha.application.dto.response.DashboardAlertResponse;
import com.bousselha.application.dto.response.DashboardResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Car;
import com.bousselha.domain.model.Contract;
import com.bousselha.domain.repository.CarRepository;
import com.bousselha.domain.repository.ContractRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@Transactional
public class DashboardService {
    private static final int INSURANCE_ALERT_DAYS = 30;
    private static final int INSPECTION_ALERT_DAYS = 30;
    private static final int OIL_CHANGE_DELAY_DAYS = 180;

    private final CarRepository carRepository;
    private final ContractRepository contractRepository;
    private final ContractService contractService;
    private final FinancialService financialService;

    public DashboardService(
            CarRepository carRepository,
            ContractRepository contractRepository,
            ContractService contractService,
            FinancialService financialService
    ) {
        this.carRepository = carRepository;
        this.contractRepository = contractRepository;
        this.contractService = contractService;
        this.financialService = financialService;
    }

    public DashboardResponse stats() {
        BigDecimal income = financialService.totalIncome();
        BigDecimal expense = financialService.totalExpense();
        return new DashboardResponse(
                carRepository.count(),
                carRepository.findByStatus(CarStatus.AVAILABLE).size(),
                carRepository.findByStatus(CarStatus.RENTED).size(),
                carRepository.findByStatus(CarStatus.MAINTENANCE).size(),
                income,
                expense
        );
    }

    public List<ContractResponse> calendar() {
        return contractService.findActive();
    }

    public List<ContractResponse> getFutureReservations() {
        return contractService.findInProgressFutureReservations();
    }

    public List<DashboardAlertResponse> alerts() {
        contractService.autoActivateContracts();

        LocalDate now = LocalDate.now();
        LocalDate insuranceWarningDate = now.plusDays(INSURANCE_ALERT_DAYS);
        LocalDate inspectionWarningDate = now.plusDays(INSPECTION_ALERT_DAYS);
        LocalDate oilDelayLimit = now.minusDays(OIL_CHANGE_DELAY_DAYS);

        List<DashboardAlertResponse> alerts = new ArrayList<>();

        // 1. Alertes de retour pour les contrats ACTIVE
        List<Contract> activeContracts = contractRepository.findDetailedByStatus(ContractStatus.ACTIVE);
        LocalDateTime limit24h = LocalDateTime.now().plusHours(24);
        for (Contract contract : activeContracts) {
            LocalDateTime returnTime = contract.getExpectedReturnDatetime();
            if (returnTime != null) {
                if (LocalDateTime.now().isAfter(returnTime)) {
                    // Retour dépassé
                    String carLabel = contract.getCar().getBrand() + " - " + contract.getCar().getMatricule();
                    alerts.add(new DashboardAlertResponse(
                            "RETURN",
                            contract.getCar().getId(),
                            carLabel,
                            "Retour depasse pour " + contract.getClient().getFullName(),
                            "HIGH",
                            returnTime.toLocalDate(),
                            contract.getId()
                    ));
                } else if (LocalDateTime.now().isAfter(returnTime.minusHours(24))) {
                    // Retour prévu dans moins de 24h
                    String carLabel = contract.getCar().getBrand() + " - " + contract.getCar().getMatricule();
                    alerts.add(new DashboardAlertResponse(
                            "RETURN",
                            contract.getCar().getId(),
                            carLabel,
                            "Retour prevu dans moins de 24h pour " + contract.getClient().getFullName(),
                            "MEDIUM",
                            returnTime.toLocalDate(),
                            contract.getId()
                    ));
                }
            }
        }

        // 2. Alertes véhicules (assurance, inspection, vidange)
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
                        car.getInsuranceExpiryDate(),
                        null
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
                        car.getNextInspectionDate(),
                        null
                ));
            }

            if (car.getLastOilChangeDate() != null && car.getLastOilChangeDate().isBefore(oilDelayLimit)) {
                alerts.add(new DashboardAlertResponse(
                        "OIL_CHANGE",
                        car.getId(),
                        carLabel,
                        "Vidange en retard",
                        "MEDIUM",
                        car.getLastOilChangeDate(),
                        null
                ));
            }
        }
        return alerts;
    }
}
