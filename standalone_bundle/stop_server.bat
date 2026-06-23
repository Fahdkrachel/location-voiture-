@echo off
setlocal
cd /d "%~dp0"

echo ==============================================
echo       BOUSSELHA CARS - Arret du Serveur
echo ==============================================

echo [1/2] Arret du Backend Spring Boot...
taskkill /F /IM java.exe /T > nul 2>&1

echo [2/2] Arret de la base de donnees MariaDB...
"mariadb\bin\mysqladmin.exe" -u root shutdown > nul 2>&1
timeout /t 2 /nobreak > nul
taskkill /F /IM mysqld.exe /T > nul 2>&1

echo.
echo Le serveur a ete arrete.
timeout /t 2 /nobreak > nul
exit
