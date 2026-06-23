# Script de restauration de la base de données BOUSSELHA CARS
$backupDir = Join-Path $PSScriptRoot "backups"

if (-not (Test-Path $backupDir)) {
    Write-Host "Le dossier 'backups' n'existe pas. Aucune sauvegarde à restaurer." -ForegroundColor Red
    exit
}

# Lister les fichiers SQL disponibles dans backups/
$files = Get-ChildItem -Path $backupDir -Filter "*.sql" | Sort-Object LastWriteTime -Descending

if ($files.Count -eq 0) {
    Write-Host "Aucun fichier de sauvegarde (.sql) trouvé dans $backupDir." -ForegroundColor Red
    exit
}

Write-Host "=== SAUVEGARDES DISPONIBLES ===" -ForegroundColor Cyan
for ($i = 0; $i -lt $files.Count; $i++) {
    Write-Host "[$i] $($files[$i].Name) ($($files[$i].Length / 1KB -as [int]) KB) - $($files[$i].LastWriteTime)"
}

$choice = Read-Host "Entrez le numéro de la sauvegarde à restaurer (ou presser Entrée pour annuler)"
if ([string]::IsNullOrWhiteSpace($choice)) {
    Write-Host "Restauration annulée." -ForegroundColor Yellow
    exit
}

# Vérifier si l'entrée est bien un nombre valide
if (-not [int]::TryParse($choice, [ref]$index)) {
    Write-Host "Index invalide." -ForegroundColor Red
    exit
}

if ($index -lt 0 -or $index -ge $files.Count) {
    Write-Host "Index invalide." -ForegroundColor Red
    exit
}

$selectedFile = $files[$index].FullName
Write-Host "Vous avez sélectionné : $($files[$index].Name)" -ForegroundColor Yellow
$confirm = Read-Host "ATTENTION : Cela va écraser la base de données actuelle. Confirmer par 'OUI'"

if ($confirm -ne "OUI") {
    Write-Host "Restauration annulée." -ForegroundColor Yellow
    exit
}

Write-Host "Restauration en cours..." -ForegroundColor Cyan

# Lancer mysql (détecte si standalone ou Docker)
$MysqlPath = Join-Path $PSScriptRoot "standalone_bundle\mariadb\bin\mysql.exe"

if (Test-Path $MysqlPath) {
    Write-Host "Mode Standalone détecté. Utilisation de mysql local..." -ForegroundColor Yellow
    # Exécuter mysql sur le port 3309 (sans mot de passe pour root)
    Get-Content $selectedFile | & $MysqlPath -u root -P 3309 bousselha_db
} else {
    Write-Host "Mode Docker détecté. Utilisation du conteneur..." -ForegroundColor Yellow
    Get-Content $selectedFile | docker exec -i bousselha-db mysql -u bousselha -pBousselha@2026 bousselha_db
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Restauration réussie avec succès !" -ForegroundColor Green
} else {
    Write-Host "Erreur lors de la restauration." -ForegroundColor Red
}
