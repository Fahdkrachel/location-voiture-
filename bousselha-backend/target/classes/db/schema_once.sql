-- Scripts à exécuter UNE SEULE FOIS sur MySQL (bousselha_db).
-- Ne pas relancer si les colonnes/tables existent déjà.

-- Table des paramètres société (singleton, id=1 toujours)
CREATE TABLE IF NOT EXISTS company_settings (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL DEFAULT 'BOUSSELHA CARS',
    address      VARCHAR(500) DEFAULT 'Branes 1, Rue Ibn Chahid N°11 - Tanger',
    phone        VARCHAR(50)  DEFAULT '05 39 31 54 63',
    fax          VARCHAR(50)  DEFAULT '05 39 31 54 63',
    gsm          VARCHAR(200) DEFAULT '06 89 12 48 89 / 06 61 54 99 92',
    email        VARCHAR(200) DEFAULT 'bousselhaa@gmail.com',
    website      VARCHAR(300) DEFAULT NULL,
    logo_path    VARCHAR(500) DEFAULT NULL,
    updated_at   DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insérer le row par défaut si absent
INSERT INTO company_settings (id, company_name, address, phone, fax, gsm, email)
SELECT 1, 'BOUSSELHA CARS', 'Branes 1, Rue Ibn Chahid N°11 - Tanger',
       '05 39 31 54 63', '05 39 31 54 63', '06 89 12 48 89 / 06 61 54 99 92',
       'bousselhaa@gmail.com'
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM company_settings WHERE id = 1);

-- Statut contrat IN_PROGRESS (si ancienne colonne ENUM)
ALTER TABLE contracts
    MODIFY COLUMN status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS';

-- Statut maintenance (exécuter une seule fois ; ignorer si la colonne existe déjà)
ALTER TABLE maintenance
    ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS';

-- Tables financières (si absentes — Hibernate ddl-auto=none ne les crée plus)
CREATE TABLE IF NOT EXISTS income_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(19,2) NOT NULL,
    recorded_at DATETIME NOT NULL,
    source VARCHAR(30) NOT NULL,
    description TEXT,
    contract_id BIGINT,
    client_id BIGINT,
    client_name VARCHAR(200),
    created_by VARCHAR(120) DEFAULT 'Administrateur'
);

-- Si income_records existait sans client_id / client_name (voir aussi add_income_client_columns.sql) :
-- ALTER TABLE income_records ADD COLUMN client_id BIGINT NULL;
-- ALTER TABLE income_records ADD COLUMN client_name VARCHAR(200) NULL;

CREATE TABLE IF NOT EXISTS expense_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(19,2) NOT NULL,
    recorded_at DATETIME NOT NULL,
    source VARCHAR(30) NOT NULL,
    category VARCHAR(80),
    description TEXT,
    maintenance_id BIGINT,
    car_name VARCHAR(200),
    created_by VARCHAR(120) DEFAULT 'Administrateur'
);
