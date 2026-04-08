@echo off
title Obsidian Quick Sync - Watcher
cd /d "%~dp0"
echo Starting Obsidian Quick Sync watcher...
echo Drop .html files into this folder to publish.
echo Close this window to stop.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0watcher.ps1"
pause
