@echo off
REM Build script for XOGENT Winget Auto-Updater
REM This is a wrapper for the PowerShell build script
REM Copyright (c) XOGENT, INC 2024

powershell.exe -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
exit /b %ERRORLEVEL%

