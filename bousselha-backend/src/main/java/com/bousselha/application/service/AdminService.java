package com.bousselha.application.service;

import com.bousselha.domain.model.Admin;
import com.bousselha.domain.repository.AdminRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AdminService {
    private final AdminRepository adminRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public AdminService(AdminRepository adminRepository, BCryptPasswordEncoder passwordEncoder) {
        this.adminRepository = adminRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public Admin createAdmin(String fullName, String email, String phone, String rawPassword) {
        Admin a = new Admin();
        a.setFullName(fullName);
        a.setEmail(email.toLowerCase());
        a.setPhone(phone);
        a.setPasswordHash(passwordEncoder.encode(rawPassword));
        a.setStatus("ACTIVE");
        return adminRepository.save(a);
    }

    public Admin findByEmail(String email) {
        return adminRepository.findByEmail(email.toLowerCase()).orElse(null);
    }

    public List<Admin> findAll() {
        return adminRepository.findAll();
    }

    public void updateLastLogin(Admin admin) {
        admin.setLastLogin(LocalDateTime.now());
        adminRepository.save(admin);
    }

    public boolean checkPassword(Admin admin, String rawPassword) {
        return passwordEncoder.matches(rawPassword, admin.getPasswordHash());
    }

    public Admin changePassword(Admin admin, String rawPassword) {
        admin.setPasswordHash(passwordEncoder.encode(rawPassword));
        return adminRepository.save(admin);
    }

    public Admin setStatus(Admin admin, String status) {
        admin.setStatus(status);
        return adminRepository.save(admin);
    }

    public Admin findById(Long id) {
        return adminRepository.findById(id).orElse(null);
    }

    public Admin updateAdmin(Long id, String fullName, String email, String phone) {
        Admin admin = adminRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Administrateur non trouvé"));
        admin.setFullName(fullName);
        admin.setEmail(email.toLowerCase());
        admin.setPhone(phone);
        return adminRepository.save(admin);
    }
}

