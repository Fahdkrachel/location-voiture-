@echo off
setlocal
cd /d "%~dp0"

:: Demarrer le serveur en arriere-plan
call standalone_bundle\start_server.bat

:: Lancer l'application Flutter
start "" "bousselha_flutter.exe"
exit
