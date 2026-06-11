package com.bousselha.domain.repository;

import com.bousselha.domain.model.IncomeRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface IncomeRecordRepository extends JpaRepository<IncomeRecord, Long> {
    List<IncomeRecord> findAllByContractId(Long contractId);

    boolean existsByContractId(Long contractId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from IncomeRecord i where i.contractId = :contractId")
    void deleteByContractId(@Param("contractId") Long contractId);

    @Query("select coalesce(sum(i.amount), 0) from IncomeRecord i")
    BigDecimal sumAll();

    List<IncomeRecord> findAllByOrderByRecordedAtDesc();

    @Query("""
            select i from IncomeRecord i
            where (:from is null or i.recordedAt >= :from)
              and (:to is null or i.recordedAt <= :to)
              and (:source is null or i.source = :source)
              and (:minAmount is null or i.amount >= :minAmount)
              and (:maxAmount is null or i.amount <= :maxAmount)
            order by i.recordedAt desc
            """)
    List<IncomeRecord> search(
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            @Param("source") com.bousselha.domain.enums.IncomeSource source,
            @Param("minAmount") BigDecimal minAmount,
            @Param("maxAmount") BigDecimal maxAmount
    );
}
