package com.bousselha.domain.repository;

import com.bousselha.domain.model.Admin;
import com.bousselha.domain.model.PasswordResetToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    boolean existsByCodeHash(String codeHash);

    long countByRequestedEmailAndCreatedAtAfter(String requestedEmail, LocalDateTime after);

    Optional<PasswordResetToken> findByAdminAndCodeHash(Admin admin, String codeHash);

    Optional<PasswordResetToken> findTopByAdminAndUsedAtIsNullOrderByCreatedAtDesc(Admin admin);

    void deleteByExpiresAtBefore(LocalDateTime dateTime);
}
