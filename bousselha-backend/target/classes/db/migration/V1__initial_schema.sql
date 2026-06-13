-- Initial schema creation for BOUSSELHA CARS
-- Using IF NOT EXISTS to allow running on top of existing local databases

-- 1. Cars table
CREATE TABLE IF NOT EXISTS cars (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    brand VARCHAR(100) NOT NULL,
    fuel_type VARCHAR(20) NOT NULL,
    matricule VARCHAR(50) NOT NULL,
    next_inspection_date DATE NULL,
    last_oil_change_date DATE NULL,
    insurance_expiry_date DATE NULL,
    mileage BIGINT NOT NULL DEFAULT 0,
    mileage_updated_at DATETIME NULL,
    image_url VARCHAR(300) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    created_at DATETIME NULL,
    updated_at DATETIME NULL,
    UNIQUE KEY uk_cars_matricule (matricule)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Clients table
CREATE TABLE IF NOT EXISTS clients (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    birth_date DATE NULL,
    address_morocco VARCHAR(500) NULL,
    address_abroad VARCHAR(500) NULL,
    profession VARCHAR(100) NULL,
    driving_license_number VARCHAR(100) NULL,
    driving_license_issued_at VARCHAR(100) NULL,
    cin_number VARCHAR(50) NULL,
    passport_number VARCHAR(100) NULL,
    phone VARCHAR(50) NULL,
    passport_issued_at DATE NULL,
    additional_driver_full_name VARCHAR(200) NULL,
    additional_driver_driving_license_number VARCHAR(100) NULL,
    additional_driver_driving_license_issued_at DATE NULL,
    additional_driver_passport_number VARCHAR(100) NULL,
    created_at DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Contracts table
CREATE TABLE IF NOT EXISTS contracts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    car_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    additional_driver_name VARCHAR(200) NULL,
    additional_driver_license VARCHAR(100) NULL,
    additional_driver_passport VARCHAR(100) NULL,
    departure_place VARCHAR(200) NULL,
    return_place VARCHAR(200) NULL,
    departure_datetime DATETIME NULL,
    expected_return_datetime DATETIME NULL,
    actual_return_datetime DATETIME NULL,
    duration_days INT NULL,
    price_per_day DECIMAL(19, 2) NULL,
    price_per_week DECIMAL(19, 2) NULL,
    price_per_month DECIMAL(19, 2) NULL,
    price_per_hour DECIMAL(19, 2) NULL,
    with_insurance BOOLEAN NOT NULL DEFAULT FALSE,
    total_price DECIMAL(19, 2) NULL,
    supplement DECIMAL(19, 2) NULL,
    total_general DECIMAL(19, 2) NULL,
    payment_cash DECIMAL(19, 2) NULL,
    payment_check DECIMAL(19, 2) NULL,
    payment_deposit DECIMAL(19, 2) NULL,
    vehicle_condition_departure VARCHAR(500) NULL,
    vehicle_condition_return VARCHAR(500) NULL,
    damages_identified VARCHAR(500) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS',
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NULL,
    CONSTRAINT fk_contract_car FOREIGN KEY (car_id) REFERENCES cars(id),
    CONSTRAINT fk_contract_client FOREIGN KEY (client_id) REFERENCES clients(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Maintenance table
CREATE TABLE IF NOT EXISTS maintenance (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    car_id BIGINT NOT NULL,
    type VARCHAR(100) NULL,
    description TEXT NULL,
    start_date DATE NULL,
    end_date DATE NULL,
    cost DECIMAL(19, 2) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS',
    created_at DATETIME NULL,
    CONSTRAINT fk_maintenance_car FOREIGN KEY (car_id) REFERENCES cars(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Admins table
CREATE TABLE IF NOT EXISTS admins (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL,
    phone VARCHAR(50) NULL,
    password_hash VARCHAR(200) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL,
    last_login DATETIME NULL,
    UNIQUE KEY uk_admins_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Password reset tokens table
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
    CONSTRAINT fk_password_reset_admin FOREIGN KEY (admin_id) REFERENCES admins(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Company settings table
CREATE TABLE IF NOT EXISTS company_settings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL DEFAULT 'BOUSSELHA CARS',
    address VARCHAR(500) DEFAULT 'Branes 1, Rue Ibn Chahid N°11 - Tanger',
    phone VARCHAR(50) DEFAULT '05 39 31 54 63',
    fax VARCHAR(50) DEFAULT '05 39 31 54 63',
    gsm VARCHAR(200) DEFAULT '06 89 12 48 89 / 06 61 54 99 92',
    email VARCHAR(200) DEFAULT 'bousselhaa@gmail.com',
    website VARCHAR(300) DEFAULT NULL,
    logo_path VARCHAR(500) DEFAULT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Income records table
CREATE TABLE IF NOT EXISTS income_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(19, 2) NOT NULL,
    recorded_at DATETIME NOT NULL,
    source VARCHAR(30) NOT NULL,
    description TEXT NULL,
    contract_id BIGINT NULL,
    client_id BIGINT NULL,
    client_name VARCHAR(200) NULL,
    created_by VARCHAR(120) DEFAULT 'Administrateur'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Expense records table
CREATE TABLE IF NOT EXISTS expense_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(19, 2) NOT NULL,
    recorded_at DATETIME NOT NULL,
    source VARCHAR(30) NOT NULL,
    category VARCHAR(80) NULL,
    description TEXT NULL,
    maintenance_id BIGINT NULL,
    car_name VARCHAR(200) NULL,
    created_by VARCHAR(120) DEFAULT 'Administrateur'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
