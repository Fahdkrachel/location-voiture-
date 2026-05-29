-- Exécuter UNE FOIS dans bousselha_db (MySQL Workbench, etc.)

USE bousselha_db;

ALTER TABLE expense_records ADD COLUMN car_name VARCHAR(200) NULL;

UPDATE expense_records er
INNER JOIN maintenance m ON m.id = er.maintenance_id
INNER JOIN cars c ON c.id = m.car_id
SET er.car_name = CONCAT(c.brand, ' — ', c.matricule)
WHERE er.id > 0
  AND er.maintenance_id IS NOT NULL
  AND (er.car_name IS NULL OR er.car_name = '');
