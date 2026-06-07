package com.bousselha.application.controller;

import com.bousselha.application.dto.request.CreateAdminRequest;
import com.bousselha.application.dto.request.UpdateAdminRequest;
import com.bousselha.application.dto.request.UpdatePasswordRequest;
import com.bousselha.application.service.AdminService;
import com.bousselha.domain.model.Admin;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admins")
public class AdminController {
    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody CreateAdminRequest req) {
        if (!req.getPassword().equals(req.getConfirmPassword())) {
            return ResponseEntity.badRequest().body("La confirmation du mot de passe ne correspond pas.");
        }
        if (adminService.findByEmail(req.getEmail()) != null) {
            return ResponseEntity.badRequest().body("Email déjà utilisé.");
        }
        Admin a = adminService.createAdmin(req.getFullName(), req.getEmail(), req.getPhone(), req.getPassword());
        return ResponseEntity.ok(a);
    }

    @GetMapping
    public ResponseEntity<List<Admin>> list() {
        return ResponseEntity.ok(adminService.findAll());
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @Valid @RequestBody UpdateAdminRequest req) {
        Admin existing = adminService.findById(id);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }
        // Check email uniqueness if email changed
        if (!existing.getEmail().equalsIgnoreCase(req.getEmail()) && adminService.findByEmail(req.getEmail()) != null) {
            return ResponseEntity.badRequest().body("Email déjà utilisé par un autre compte.");
        }
        Admin updated = adminService.updateAdmin(id, req.getFullName(), req.getEmail(), req.getPhone());
        return ResponseEntity.ok(updated);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> toggleStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        Admin admin = adminService.findById(id);
        if (admin == null) {
            return ResponseEntity.notFound().build();
        }
        String status = body.get("status");
        if (status == null || (!"ACTIVE".equalsIgnoreCase(status) && !"DISABLED".equalsIgnoreCase(status))) {
            return ResponseEntity.badRequest().body("Statut invalide. Utilisez ACTIVE ou DISABLED.");
        }
        Admin updated = adminService.setStatus(admin, status.toUpperCase());
        return ResponseEntity.ok(updated);
    }

    @PatchMapping("/{id}/password")
    public ResponseEntity<?> changePassword(@PathVariable Long id, @Valid @RequestBody UpdatePasswordRequest req) {
        Admin admin = adminService.findById(id);
        if (admin == null) {
            return ResponseEntity.notFound().build();
        }
        if (!adminService.checkPassword(admin, req.getCurrentPassword())) {
            return ResponseEntity.badRequest().body("Le mot de passe actuel est incorrect.");
        }
        if (!req.getNewPassword().equals(req.getConfirmNewPassword())) {
            return ResponseEntity.badRequest().body("Le nouveau mot de passe et sa confirmation ne correspondent pas.");
        }
        Admin updated = adminService.changePassword(admin, req.getNewPassword());
        return ResponseEntity.ok(updated);
    }
}

