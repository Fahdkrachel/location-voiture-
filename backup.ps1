# Script de sauvegarde de la base de données BOUSSELHA CARS
$backupDir = Join-Path $PSScriptRoot "backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupDir "bousselha_db_backup_$timestamp.sql"

Write-Host "Démarrage de la sauvegarde de la base de données..." -ForegroundColor Cyan

# Lancer mysqldump (détecte si standalone ou Docker)
$MysqlDumpPath = Join-Path $PSScriptRoot "standalone_bundle\mariadb\bin\mysqldump.exe"

if (Test-Path $MysqlDumpPath) {
    Write-Host "Mode Standalone détecté. Utilisation de mysqldump local..." -ForegroundColor Yellow
    # Exécuter mysqldump sur le port 3309 (sans mot de passe pour root)
    & $MysqlDumpPath -u root -P 3309 bousselha_db --result-file=$backupFile
} else {
    Write-Host "Mode Docker détecté. Utilisation du conteneur..." -ForegroundColor Yellow
    docker exec -t bousselha-db mysqldump --no-tablespaces -u bousselha -pBousselha@2026 bousselha_db > $backupFile
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Sauvegarde réussie !" -ForegroundColor Green
    Write-Host "Fichier sauvegardé sous : $backupFile" -ForegroundColor Yellow
} else {
    Write-Host "Erreur lors de la sauvegarde de la base de données." -ForegroundColor Red
}
