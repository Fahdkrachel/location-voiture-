-- Ajouter le suivi du kilometrage des vehicules.
-- A executer une seule fois sur la base existante.

ALTER TABLE cars
    ADD COLUMN mileage BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN mileage_updated_at DATETIME NULL;
