@echo off
chcp 65001 > nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0施工実績管理.ps1"
if %ERRORLEVEL% neq 0 pause
