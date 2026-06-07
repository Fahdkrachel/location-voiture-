-- Migration: create admins table
-- Exécuter dans MySQL Workbench ou via script SQL

CREATE TABLE IF NOT EXISTS admins (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL,
    phone VARCHAR(50),
    password_hash VARCHAR(200) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL,
    last_login DATETIME NULL,
    UNIQUE KEY uk_admins_email (email)
);

-- Exemple: mettre à jour l'utilisateur existant unique si nécessaire
-- INSERT INTO admins (full_name, email, phone, password_hash, status, created_at)
-- VALUES ('Administrateur Principal','admin@example.com','', '<bcrypt_hash_here>', 'ACTIVE', NOW());
