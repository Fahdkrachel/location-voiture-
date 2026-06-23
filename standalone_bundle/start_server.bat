@echo off
setlocal
cd /d "%~dp0"

echo ==============================================
echo       BOUSSELHA CARS - Demarrage du Serveur
echo ==============================================

:: Demarrage de MariaDB en arriere-plan
echo [1/3] Demarrage de la base de donnees MariaDB...
start "MariaDB_Bousselha" /B "mariadb\bin\mysqld.exe" --port=3309 --console > mariadb.log 2>&1

:: Attendre quelques secondes que MariaDB demarre
timeout /t 3 /nobreak > nul

:: Creation de la base de donnees si elle n'existe pas
echo [2/3] Verification de la base de donnees...
"mariadb\bin\mysql.exe" -u root -P 3309 -e "CREATE DATABASE IF NOT EXISTS bousselha_db;" > nul 2>&1

:: Demarrage du Backend Java en arriere-plan
echo [3/3] Demarrage du Backend Spring Boot...
set JAVA_HOME=%~dp0jre
set PATH=%JAVA_HOME%\bin;%PATH%
start "Backend_Bousselha" /B "%JAVA_HOME%\bin\java.exe" -Dspring.profiles.active=standalone -jar backend.jar > backend.log 2>&1

echo.
echo Le serveur fonctionne en arriere-plan !
echo Vous pouvez maintenant ouvrir l'application BOUSSELHA CARS.
:: Attendre 2 secondes avant de fermer cette fenetre
timeout /t 2 /nobreak > nul
exit /b 0
