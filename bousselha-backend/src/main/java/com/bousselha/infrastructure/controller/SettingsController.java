package com.bousselha.infrastructure.controller;

import com.bousselha.application.dto.request.SettingsRequest;
import com.bousselha.application.dto.response.SettingsResponse;
import com.bousselha.application.service.SettingsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/settings")
public class SettingsController {

    private final SettingsService settingsService;

    public SettingsController(SettingsService settingsService) {
        this.settingsService = settingsService;
    }

    /**
     * GET /api/settings — public (utilisé par PdfService & Flutter pour afficher le logo)
     */
    @GetMapping
    public ResponseEntity<SettingsResponse> getSettings() {
        return ResponseEntity.ok(settingsService.getSettings());
    }

    /**
     * PUT /api/settings — protégé JWT
     */
    @PutMapping
    public ResponseEntity<SettingsResponse> updateSettings(@RequestBody SettingsRequest request) {
        return ResponseEntity.ok(settingsService.updateCompanyInfo(request));
    }

    /**
     * POST /api/settings/logo — protégé JWT, multipart
     */
    @PostMapping("/logo")
    public ResponseEntity<SettingsResponse> uploadLogo(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(settingsService.updateLogo(file));
    }
}
