@echo off
title AegisCare - Healthcare Diagnostic Records & Case Mix DBMS
echo =====================================================================
echo  Starting AegisCare Healthcare Diagnostic Records & Case Mix DBMS
echo =====================================================================
echo.

cd /d "%~dp0"

echo [1/2] Verifying and initializing database...
python database\init_db.py

echo.
echo [2/2] Starting web server on http://localhost:5000 ...
echo Press Ctrl+C in this window to stop the server.
echo.
start http://localhost:5000
python app.py
pause
