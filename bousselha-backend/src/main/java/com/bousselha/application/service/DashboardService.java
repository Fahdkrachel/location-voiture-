package com.bousselha.application.service;

import com.bousselha.application.dto.response.ContractResponse;
import com.bousselha.application.dto.response.DashboardResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.repository.CarRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DashboardService {
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
}
