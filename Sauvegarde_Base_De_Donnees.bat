@echo off
title Sauvegarde Base de Donnees - BOUSSELHA CARS
echo =========================================================
echo  SAUVEGARDE DE LA BASE DE DONNEES - BOUSSELHA CARS
echo =========================================================
echo.
echo Sauvegarde en cours... Veuillez patienter...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0backup.ps1"

echo.
echo =========================================================
echo Appuyez sur une touche pour fermer cette fenetre.
pause > nul
