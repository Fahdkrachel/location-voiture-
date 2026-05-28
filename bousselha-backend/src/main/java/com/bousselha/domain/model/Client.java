package com.bousselha.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "clients")
public class Client {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // SECTION 1 — LOCATAIRE
    private String fullName;
    private LocalDate birthDate;
    private String addressMorocco;
    private String addressAbroad;
    private String profession;
    private String drivingLicenseNumber;
    private String drivingLicenseIssuedAt; // ville
    private String cinNumber;
    private String passportNumber;
    private String phone;
    private LocalDate passportIssuedAt; // date

    // SECTION 2 — CONDUCTEUR SUPPLEMENTAIRE
    private String additionalDriverFullName;
    private String additionalDriverDrivingLicenseNumber;
    private LocalDate additionalDriverDrivingLicenseIssuedAt; // date
    private String additionalDriverPassportNumber;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
