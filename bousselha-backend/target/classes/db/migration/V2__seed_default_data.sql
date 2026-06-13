-- Seed default company settings if missing
INSERT INTO company_settings (id, company_name, address, phone, fax, gsm, email)
SELECT 1, 'BOUSSELHA CARS', 'Branes 1, Rue Ibn Chahid N°11 - Tanger', '05 39 31 54 63', '05 39 31 54 63', '06 89 12 48 89 / 06 61 54 99 92', 'bousselhaa@gmail.com'
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM company_settings WHERE id = 1);
