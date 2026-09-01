@echo off
REM Double-click me. Runs the project health check in a window that stays open.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CheckMyProject.ps1"
