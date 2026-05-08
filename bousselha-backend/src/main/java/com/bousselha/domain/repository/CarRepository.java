package com.bousselha.domain.repository;

import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.model.Car;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CarRepository extends JpaRepository<Car, Long> {
    List<Car> findByStatus(CarStatus status);
}
