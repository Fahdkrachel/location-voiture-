package com.bousselha.domain.repository;

import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Contract;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

import java.util.List;

public interface ContractRepository extends JpaRepository<Contract, Long> {
    List<Contract> findByDeletedFalse();
    List<Contract> findByDeletedFalseAndCarId(Long carId);
    List<Contract> findByDeletedFalseAndStatus(ContractStatus status);
    boolean existsByClientIdAndDeletedFalseAndStatus(Long clientId, ContractStatus status);
    boolean existsByCarIdAndDeletedFalseAndStatus(Long carId, ContractStatus status);

    @Query("""
            select c from Contract c
            join fetch c.client
            join fetch c.car
            where c.id = :id and c.deleted = false
            """)
    Optional<Contract> findDetailedById(@Param("id") Long id);
}
