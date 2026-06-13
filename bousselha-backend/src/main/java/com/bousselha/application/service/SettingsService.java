package com.bousselha.application.service;

import com.bousselha.application.dto.request.SettingsRequest;
import com.bousselha.application.dto.response.SettingsResponse;
import com.bousselha.domain.model.CompanySettings;
import com.bousselha.domain.repository.CompanySettingsRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Service
@Transactional
public class SettingsService {

    private static final String UPLOADS_PREFIX = "/uploads/logo/";
    private static final Long   SINGLETON_ID   = 1L;

    @Value("${app.uploads.dir}")
    private String baseUploadsDir;

    private final CompanySettingsRepository repository;

    public SettingsService(CompanySettingsRepository repository) {
        this.repository = repository;
    }

    // ── Read ────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public CompanySettings getRawSettings() {
        return repository.findById(SINGLETON_ID).orElseGet(this::createDefaults);
    }

    @Transactional(readOnly = true)
    public SettingsResponse getSettings() {
        return map(getRawSettings());
    }

    // ── Update company info ─────────────────────────────────────────────────

    public SettingsResponse updateCompanyInfo(SettingsRequest req) {
        CompanySettings s = getRawSettings();
        if (req.getCompanyName() != null && !req.getCompanyName().isBlank()) {
            s.setCompanyName(req.getCompanyName());
        }
        s.setAddress(req.getAddress());
        s.setPhone(req.getPhone());
        s.setFax(req.getFax());
        s.setGsm(req.getGsm());
        s.setEmail(req.getEmail());
        s.setWebsite(req.getWebsite());
        return map(repository.save(s));
    }

    // ── Upload logo ─────────────────────────────────────────────────────────

    public SettingsResponse updateLogo(MultipartFile file) {
        String original = Objects.requireNonNullElse(file.getOriginalFilename(), "logo.png");
        int idx = original.lastIndexOf('.');
        String ext = idx >= 0 ? original.substring(idx).toLowerCase() : ".png";
        if (!List.of(".jpg", ".jpeg", ".png").contains(ext)) {
            throw new IllegalArgumentException("Format non supporté. Utilisez JPG ou PNG.");
        }

        String filename = "company_logo" + ext;
        Path dir = Paths.get(baseUploadsDir).resolve("logo");
        try {
            Files.createDirectories(dir);
            Files.copy(file.getInputStream(), dir.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new IllegalArgumentException("Impossible d'enregistrer le logo : " + e.getMessage());
        }

        CompanySettings s = getRawSettings();
        s.setLogoPath(dir.resolve(filename).toString());
        return map(repository.save(s));
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private CompanySettings createDefaults() {
        CompanySettings s = new CompanySettings();
        s.setId(SINGLETON_ID);
        s.setCompanyName("BOUSSELHA CARS");
        s.setAddress("Branes 1, Rue Ibn Chahid N°11 - Tanger");
        s.setPhone("05 39 31 54 63");
        s.setFax("05 39 31 54 63");
        s.setGsm("06 89 12 48 89 / 06 61 54 99 92");
        s.setEmail("bousselhaa@gmail.com");
        return repository.save(s);
    }

    private SettingsResponse map(CompanySettings s) {
        String logoUrl = null;
        if (s.getLogoPath() != null && !s.getLogoPath().isBlank()) {
            // Extraire juste le nom du fichier pour construire l'URL publique
            String filename = Paths.get(s.getLogoPath()).getFileName().toString();
            logoUrl = UPLOADS_PREFIX + filename;
        }
        return new SettingsResponse(
                s.getId(), s.getCompanyName(), s.getAddress(),
                s.getPhone(), s.getFax(), s.getGsm(), s.getEmail(),
                s.getWebsite(), logoUrl, s.getUpdatedAt()
        );
    }
}
