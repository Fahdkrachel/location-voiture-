-- Scripts à exécuter UNE SEULE FOIS sur MySQL (bousselha_db).
-- Ne pas relancer si les colonnes/tables existent déjà.

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
