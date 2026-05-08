package com.bousselha.domain.repository;

import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Contract;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ContractRepository extends JpaRepository<Contract, Long> {
    List<Contract> findByDeletedFalse();
    List<Contract> findByDeletedFalseAndStatus(ContractStatus status);
}
