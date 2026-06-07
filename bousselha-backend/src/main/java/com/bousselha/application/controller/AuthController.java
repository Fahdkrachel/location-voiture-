package com.bousselha.application.controller;

import com.bousselha.application.dto.request.LoginRequest;
import com.bousselha.application.dto.response.LoginResponse;
import com.bousselha.application.service.AdminService;
import com.bousselha.domain.model.Admin;
import com.bousselha.security.JwtProvider;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AdminService adminService;
    private final JwtProvider jwtProvider;

    public AuthController(AdminService adminService, JwtProvider jwtProvider) {
        this.adminService = adminService;
        this.jwtProvider = jwtProvider;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        Admin admin = adminService.findByEmail(request.getEmail());
        if (admin == null) {
            return ResponseEntity.status(401).body("Identifiants invalides");
        }
        if (!"ACTIVE".equalsIgnoreCase(admin.getStatus())) {
            return ResponseEntity.status(403).body("Compte désactivé");
        }
        if (!adminService.checkPassword(admin, request.getPassword())) {
            return ResponseEntity.status(401).body("Identifiants invalides");
        }

        String token = jwtProvider.generateToken(admin.getEmail());
        adminService.updateLastLogin(admin);
        return ResponseEntity.ok(new LoginResponse(token, admin.getId(), admin.getFullName(), admin.getEmail()));
    }

    @GetMapping("/me")
    public ResponseEntity<?> me() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null || !(auth.getPrincipal() instanceof String)) {
            return ResponseEntity.status(401).build();
        }
        String email = (String) auth.getPrincipal();
        Admin admin = adminService.findByEmail(email);
        if (admin == null) return ResponseEntity.status(404).build();
        return ResponseEntity.ok(admin);
    }
}
