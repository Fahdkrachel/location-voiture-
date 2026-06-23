$ErrorActionPreference = "Stop"
$BundleDir = "$PSScriptRoot\standalone_bundle"

Write-Host "====================================================="
Write-Host "  Préparation de l'environnement Standalone (V2)"
Write-Host "====================================================="

# 1. Création du dossier principal
if (!(Test-Path $BundleDir)) {
    New-Item -ItemType Directory -Path $BundleDir | Out-Null
}

# 2. Compilation du Backend Java
Write-Host "`n[1/4] Compilation du Backend Spring Boot..."
Set-Location "$PSScriptRoot\bousselha-backend"
# On tente d'utiliser l'outil maven inclus (mvnw), sinon on essaie 'mvn'
if (Test-Path ".\mvnw.cmd") {
    .\mvnw.cmd clean package -DskipTests
} else {
    mvn clean package -DskipTests
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de la compilation du backend. Vérifiez le code." -ForegroundColor Red
    exit 1
}

Write-Host "Copie du fichier .jar vers le bundle..."
$jarFile = Get-ChildItem -Path ".\target" -Filter "*.jar" | Where-Object { $_.Name -notmatch "plain" } | Select-Object -First 1
Copy-Item $jarFile.FullName -Destination "$BundleDir\backend.jar" -Force
Set-Location $PSScriptRoot

# 3. Téléchargement de Java (JRE 17 Portable)
$JreUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jre_x64_windows_hotspot_17.0.11_9.zip"
$JreZip = "$BundleDir\jre.zip"
$JreDir = "$BundleDir\jre"

Write-Host "`n[2/4] Téléchargement de Java (JRE 17 Portable)... (Cela peut prendre quelques minutes)"
if (!(Test-Path $JreDir)) {
    if (!(Test-Path $JreZip)) {
        Invoke-WebRequest -Uri $JreUrl -OutFile $JreZip
    }
    Write-Host "Extraction de Java..."
    Expand-Archive -Path $JreZip -DestinationPath $BundleDir -Force
    # Renommer le dossier extrait (qui a un nom long) en "jre"
    $extractedFolder = Get-ChildItem -Path $BundleDir -Directory -Filter "jdk-17*" | Select-Object -First 1
    Rename-Item -Path $extractedFolder.FullName -NewName "jre"
    Remove-Item $JreZip
} else {
    Write-Host "Java est déjà présent."
}

# 4. Téléchargement de MariaDB (Portable)
$MariaDbUrl = "https://archive.mariadb.org/mariadb-11.4.2/winx64-packages/mariadb-11.4.2-winx64.zip"
$MariaDbZip = "$BundleDir\mariadb.zip"
$MariaDbDir = "$BundleDir\mariadb"

Write-Host "`n[3/4] Téléchargement de MariaDB Portable... (Cela peut prendre quelques minutes)"
if (!(Test-Path $MariaDbDir)) {
    if (!(Test-Path $MariaDbZip)) {
        Invoke-WebRequest -Uri $MariaDbUrl -OutFile $MariaDbZip
    }
    Write-Host "Extraction de MariaDB..."
    Expand-Archive -Path $MariaDbZip -DestinationPath $BundleDir -Force
    $extractedFolder = Get-ChildItem -Path $BundleDir -Directory -Filter "mariadb-*" | Select-Object -First 1
    Rename-Item -Path $extractedFolder.FullName -NewName "mariadb"
    Remove-Item $MariaDbZip
} else {
    Write-Host "MariaDB est déjà présent."
}

# 5. Initialisation de la base de données
Write-Host "`n[4/4] Configuration initiale de la base de données..."
$MariaDbDataDir = "$BundleDir\mariadb\data"
if (!(Test-Path $MariaDbDataDir)) {
    # Exécuter l'outil d'installation de MariaDB pour créer les tables systèmes
    $installDbCmd = "$BundleDir\mariadb\bin\mysql_install_db.exe"
    & $installDbCmd --datadir="$MariaDbDataDir" | Out-Null
    Write-Host "Base de données initialisée avec succès."
} else {
    Write-Host "La base de données est déjà initialisée."
}

Write-Host "`n====================================================="
Write-Host " Préparation terminée ! Le dossier 'standalone_bundle' est prêt." -ForegroundColor Green
Write-Host "====================================================="
