package com.bousselha.application.service;

import com.bousselha.domain.repository.AdminRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class AdminInitializer implements ApplicationRunner {
    private static final Logger logger = LoggerFactory.getLogger(AdminInitializer.class);

    private final AdminRepository adminRepository;
    private final AdminService adminService;

    public AdminInitializer(AdminRepository adminRepository, AdminService adminService) {
        this.adminRepository = adminRepository;
        this.adminService = adminService;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        long count = 0;
        try {
            count = adminRepository.count();
        } catch (Exception ex) {
            logger.warn("Could not query admins table (may not exist yet). Run DB migration first. Error: {}", ex.getMessage());
            return;
        }
        if (count == 0) {
            String email = System.getenv("INITIAL_ADMIN_EMAIL");
            String password = System.getenv("INITIAL_ADMIN_PASSWORD");
            String name = System.getenv("INITIAL_ADMIN_NAME");
            if (email != null && password != null) {
                String n = name != null ? name : "Administrateur";
                adminService.createAdmin(n, email, "", password);
                logger.info("Initial admin created for email={}", email);
            } else {
                logger.info("No initial admin config found in env. Creating fallback admin: admin@bousselha.ma / Admin@2026");
                adminService.createAdmin("Administrateur Principal", "admin@bousselha.ma", "0689124889", "Admin@2026");
            }
        }
    }
}
