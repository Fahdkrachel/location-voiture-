package com.bousselha.domain.repository;

import com.bousselha.domain.model.CompanySettings;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CompanySettingsRepository extends JpaRepository<CompanySettings, Long> {
}
