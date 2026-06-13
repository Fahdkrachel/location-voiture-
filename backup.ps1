# Script de sauvegarde de la base de données BOUSSELHA CARS
$backupDir = Join-Path $PSScriptRoot "backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupDir "bousselha_db_backup_$timestamp.sql"

Write-Host "Démarrage de la sauvegarde de la base de données..." -ForegroundColor Cyan

# Lancer mysqldump depuis le conteneur Docker
docker exec -t bousselha-db mysqldump --no-tablespaces -u bousselha -pBousselha@2026 bousselha_db > $backupFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Sauvegarde réussie !" -ForegroundColor Green
    Write-Host "Fichier sauvegardé sous : $backupFile" -ForegroundColor Yellow
} else {
    Write-Host "Erreur lors de la sauvegarde de la base de données." -ForegroundColor Red
}
