package com.bousselha.domain.repository;

import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Contract;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Optional;

import java.util.List;

public interface ContractRepository extends JpaRepository<Contract, Long> {
    List<Contract> findByDeletedFalse();
    List<Contract> findByDeletedFalseAndCarId(Long carId);
    List<Contract> findByDeletedFalseAndStatus(ContractStatus status);
    List<Contract> findByDeletedFalseAndStatusIn(Collection<ContractStatus> statuses);
    boolean existsByClientIdAndDeletedFalseAndStatus(Long clientId, ContractStatus status);
    boolean existsByCarIdAndDeletedFalseAndStatus(Long carId, ContractStatus status);
    boolean existsByClientIdAndDeletedFalseAndStatusIn(Long clientId, Collection<ContractStatus> statuses);
    boolean existsByCarIdAndDeletedFalseAndStatusIn(Long carId, Collection<ContractStatus> statuses);

    @Query("""
            select c from Contract c
            join fetch c.client
            join fetch c.car
            where c.deleted = false and c.status = :status
            """)
    List<Contract> findDetailedByStatus(@Param("status") ContractStatus status);

    long countByDeletedFalseAndClientId(Long clientId);

    long countByClientId(Long clientId);

    List<Contract> findByClientId(Long clientId);

    @Query("""
            select c from Contract c
            join fetch c.client
            join fetch c.car
            where c.car.id = :carId
            order by c.departureDatetime desc
            """)
    List<Contract> findByCarIdForHistory(@Param("carId") Long carId);

    @Query("""
            select c from Contract c
            join fetch c.client
            join fetch c.car
            where c.id = :id and c.deleted = false
            """)
    Optional<Contract> findDetailedById(@Param("id") Long id);
}
