-- Migration: create password reset tokens table
-- Exécuter dans MySQL Workbench ou via script SQL avant d'utiliser la récupération de mot de passe.

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT NOT NULL,
    requested_email VARCHAR(200) NOT NULL,
    code_hash VARCHAR(64) NOT NULL,
    created_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    failed_attempts INT NOT NULL DEFAULT 0,
    UNIQUE KEY uk_password_reset_code_hash (code_hash),
    KEY idx_password_reset_admin (admin_id),
    KEY idx_password_reset_email (requested_email),
    KEY idx_password_reset_expires (expires_at),
    CONSTRAINT fk_password_reset_admin FOREIGN KEY (admin_id) REFERENCES admins(id)
);
