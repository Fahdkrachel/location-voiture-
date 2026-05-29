-- Exécuter UNE FOIS dans bousselha_db (MySQL Workbench, HeidiSQL, etc.)
-- Si une colonne existe déjà, ignorer l'erreur correspondante ou commenter la ligne.

USE bousselha_db;

ALTER TABLE income_records ADD COLUMN client_id BIGINT NULL;
ALTER TABLE income_records ADD COLUMN client_name VARCHAR(200) NULL;

-- Remplir les revenus déjà liés à un contrat (optionnel ; compatible mode "safe updates")
UPDATE income_records ir
INNER JOIN contracts c ON c.id = ir.contract_id
INNER JOIN clients cl ON cl.id = c.client_id
SET ir.client_id = cl.id, ir.client_name = cl.full_name
WHERE ir.id > 0
  AND ir.contract_id IS NOT NULL
  AND ir.client_id IS NULL;
