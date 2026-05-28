package com.bousselha.domain.model;

import com.bousselha.domain.enums.ContractStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "contracts")
public class Contract {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "car_id")
    private Car car;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "client_id")
    private Client client;

    private String additionalDriverName;
    private String additionalDriverLicense;
    private String additionalDriverPassport;
    private String departurePlace;
    private String returnPlace;
    private LocalDateTime departureDatetime;
    private LocalDateTime expectedReturnDatetime;
    private LocalDateTime actualReturnDatetime;
    private Integer durationDays;
    private BigDecimal pricePerDay;
    private BigDecimal pricePerWeek;
    private BigDecimal pricePerMonth;
    private BigDecimal pricePerHour;
    private Boolean withInsurance;
    private BigDecimal totalPrice;
    private BigDecimal supplement;
    private BigDecimal totalGeneral;
    private BigDecimal paymentCash;
    private BigDecimal paymentCheck;
    private BigDecimal paymentDeposit;
    private String vehicleConditionDeparture;
    private String vehicleConditionReturn;
    private String damagesIdentified;

    @Enumerated(EnumType.STRING)
    @Column(length = 30, nullable = false)
    private ContractStatus status = ContractStatus.IN_PROGRESS;

    @Column(name = "deleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
