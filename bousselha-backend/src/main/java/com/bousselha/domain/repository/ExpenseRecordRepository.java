package com.bousselha.domain.repository;

import com.bousselha.domain.model.ExpenseRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface ExpenseRecordRepository extends JpaRepository<ExpenseRecord, Long> {
    Optional<ExpenseRecord> findByMaintenanceId(Long maintenanceId);

    @Query("select coalesce(sum(e.amount), 0) from ExpenseRecord e")
    BigDecimal sumAll();

    List<ExpenseRecord> findAllByOrderByRecordedAtDesc();

    @Query("""
            select e from ExpenseRecord e
            where (:from is null or e.recordedAt >= :from)
              and (:to is null or e.recordedAt <= :to)
              and (:source is null or e.source = :source)
              and (:category is null or lower(e.category) like lower(concat('%', :category, '%')))
            order by e.recordedAt desc
            """)
    List<ExpenseRecord> search(
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            @Param("source") com.bousselha.domain.enums.ExpenseSource source,
            @Param("category") String category
    );
}
