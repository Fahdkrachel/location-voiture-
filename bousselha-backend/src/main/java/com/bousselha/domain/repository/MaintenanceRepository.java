package com.bousselha.domain.repository;

import com.bousselha.domain.enums.MaintenanceStatus;
import com.bousselha.domain.model.Maintenance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MaintenanceRepository extends JpaRepository<Maintenance, Long> {
    List<Maintenance> findByCarId(Long carId);

    boolean existsByCarIdAndStatus(Long carId, MaintenanceStatus status);
}
