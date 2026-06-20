@echo off
chcp 65001 >nul
echo ============================================================
echo  POS Panel - Otomatik Kurulum
echo ============================================================
echo.
echo  1) Auto-login eklentisi (Chrome'a otomatik kurulur)
echo  2) Windows acilisinda Chrome otomatik acilir
echo  3) Her gun 08:00'da Chrome kapaliysa acilir
echo.
echo  NOT: Yonetici izni penceresi cikacak, "Evet" de.
echo  NOT: Kurulum sonunda Chrome TAMAMEN kapatilip yeniden acilir.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0kurulum.ps1"
