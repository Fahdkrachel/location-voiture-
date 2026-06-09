package com.bousselha.application.service;

import com.bousselha.domain.model.Admin;
import com.bousselha.domain.model.PasswordResetToken;
import com.bousselha.domain.repository.AdminRepository;
import com.bousselha.domain.repository.PasswordResetTokenRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class PasswordResetService {
    private static final int CODE_TTL_MINUTES = 10;
    private static final int MAX_REQUESTS_PER_HOUR = 3;
    private static final int MAX_FAILED_ATTEMPTS = 5;

    private final AdminRepository adminRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final SecureRandom secureRandom = new SecureRandom();
    private final Map<String, List<LocalDateTime>> requestAttemptsByEmail = new ConcurrentHashMap<>();

    public PasswordResetService(
            AdminRepository adminRepository,
            PasswordResetTokenRepository tokenRepository,
            BCryptPasswordEncoder passwordEncoder,
            EmailService emailService
    ) {
        this.adminRepository = adminRepository;
        this.tokenRepository = tokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }

    @Transactional
    public void requestReset(String email) {
        String normalizedEmail = normalizeEmail(email);
        cleanupExpiredTokens();
        registerRequestAttempt(normalizedEmail);

        if (tokenRepository.countByRequestedEmailAndCreatedAtAfter(
                normalizedEmail,
                LocalDateTime.now().minusHours(1)
        ) >= MAX_REQUESTS_PER_HOUR) {
            throw new IllegalArgumentException("RESET_REQUEST_LIMIT_REACHED");
        }

        Admin admin = adminRepository.findByEmail(normalizedEmail).orElse(null);
        if (admin == null || !"ACTIVE".equalsIgnoreCase(admin.getStatus())) {
            return;
        }

        String code = generateUniqueCode();
        PasswordResetToken token = new PasswordResetToken();
        token.setAdmin(admin);
        token.setRequestedEmail(normalizedEmail);
        token.setCodeHash(hashCode(code));
        token.setCreatedAt(LocalDateTime.now());
        token.setExpiresAt(LocalDateTime.now().plusMinutes(CODE_TTL_MINUTES));
        tokenRepository.save(token);

        emailService.sendPasswordResetCode(admin.getEmail(), code);
    }

    @Transactional
    public void verifyCode(String email, String code) {
        findValidToken(email, code);
    }

    @Transactional
    public void resetPassword(String email, String code, String newPassword, String confirmNewPassword) {
        if (!newPassword.equals(confirmNewPassword)) {
            throw new IllegalArgumentException("PASSWORD_CONFIRMATION_MISMATCH");
        }
        if (!isStrongPassword(newPassword)) {
            throw new IllegalArgumentException("WEAK_PASSWORD");
        }

        PasswordResetToken token = findValidToken(email, code);
        Admin admin = token.getAdmin();
        admin.setPasswordHash(passwordEncoder.encode(newPassword));
        token.setUsedAt(LocalDateTime.now());
        adminRepository.save(admin);
        tokenRepository.save(token);
        cleanupExpiredTokens();
    }

    private PasswordResetToken findValidToken(String email, String code) {
        String normalizedEmail = normalizeEmail(email);
        Admin admin = adminRepository.findByEmail(normalizedEmail)
                .filter(a -> "ACTIVE".equalsIgnoreCase(a.getStatus()))
                .orElseThrow(() -> new IllegalArgumentException("INVALID_RESET_CODE"));

        PasswordResetToken token = tokenRepository.findByAdminAndCodeHash(admin, hashCode(code))
                .orElse(null);

        if (token == null) {
            tokenRepository.findTopByAdminAndUsedAtIsNullOrderByCreatedAtDesc(admin)
                    .ifPresent(latestToken -> {
                        latestToken.setFailedAttempts(latestToken.getFailedAttempts() + 1);
                        tokenRepository.save(latestToken);
                    });
            throw new IllegalArgumentException("INVALID_RESET_CODE");
        }

        LocalDateTime now = LocalDateTime.now();
        if (token.getUsedAt() != null) {
            throw new IllegalArgumentException("RESET_CODE_ALREADY_USED");
        }
        if (token.getExpiresAt().isBefore(now)) {
            throw new IllegalArgumentException("RESET_CODE_EXPIRED");
        }
        if (token.getFailedAttempts() >= MAX_FAILED_ATTEMPTS) {
            throw new IllegalArgumentException("RESET_CODE_BLOCKED");
        }
        return token;
    }

    private String generateUniqueCode() {
        String code;
        do {
            code = String.format("%06d", secureRandom.nextInt(1_000_000));
        } while (tokenRepository.existsByCodeHash(hashCode(code)));
        return code;
    }

    private boolean isStrongPassword(String password) {
        return password != null
                && password.length() >= 8
                && password.matches(".*[a-z].*")
                && password.matches(".*[A-Z].*")
                && password.matches(".*\\d.*")
                && password.matches(".*[^A-Za-z0-9].*");
    }

    private String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    private String hashCode(String code) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(code.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(bytes);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponible", e);
        }
    }

    private void cleanupExpiredTokens() {
        tokenRepository.deleteByExpiresAtBefore(LocalDateTime.now().minusMinutes(1));
    }

    private void registerRequestAttempt(String email) {
        LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);
        List<LocalDateTime> attempts = requestAttemptsByEmail.computeIfAbsent(email, ignored -> new ArrayList<>());
        synchronized (attempts) {
            attempts.removeIf(dateTime -> dateTime.isBefore(oneHourAgo));
            if (attempts.size() >= MAX_REQUESTS_PER_HOUR) {
                throw new IllegalArgumentException("RESET_REQUEST_LIMIT_REACHED");
            }
            attempts.add(LocalDateTime.now());
        }
    }
}
