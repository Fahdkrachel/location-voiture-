-- Exécuter une fois si l'erreur "Data truncated for column 'status'" apparaît à la création de contrat.
-- MySQL : la colonne était ENUM('ACTIVE','COMPLETED','CANCELLED') sans IN_PROGRESS.

ALTER TABLE contracts
    MODIFY COLUMN status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS';
