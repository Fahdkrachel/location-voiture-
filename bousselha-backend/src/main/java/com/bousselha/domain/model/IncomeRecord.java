package com.bousselha.domain.model;

import com.bousselha.domain.enums.IncomeSource;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "income_records")
public class IncomeRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private IncomeSource source;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "contract_id")
    private Long contractId;

    @Column(name = "client_id")
    private Long clientId;

    @Column(name = "client_name", length = 200)
    private String clientName;

    @Column(name = "created_by", length = 120)
    private String createdBy = "Administrateur";

    @PrePersist
    void onCreate() {
        if (recordedAt == null) {
            recordedAt = LocalDateTime.now();
        }
    }
}
