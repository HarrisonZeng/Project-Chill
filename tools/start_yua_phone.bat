@echo off
chcp 65001 >nul
title Yua Studio (Phone)
echo Starting Yua Studio phone server... keep this window open.
echo.
"C:\Users\zengh\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" -X utf8 "%~dp0yua_studio_web.py"
echo.
echo Server stopped. Press any key to close.
pause >nul
