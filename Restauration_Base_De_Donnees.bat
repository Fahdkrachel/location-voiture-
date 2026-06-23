@echo off
title Restauration Base de Donnees - BOUSSELHA CARS
echo =========================================================
echo  RESTAURATION DE LA BASE DE DONNEES - BOUSSELHA CARS
echo =========================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0restore.ps1"

echo.
echo =========================================================
echo Appuyez sur une touche pour fermer cette fenetre.
pause > nul
