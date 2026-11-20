# AegisCare Healthcare Diagnostic Records & Case Mix DBMS
# PowerShell Launcher Script

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " Starting AegisCare Healthcare Diagnostic Records & Case Mix DBMS" -ForegroundColor White
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

Write-Host "[1/2] Verifying and initializing database..." -ForegroundColor Yellow
python database/init_db.py

Write-Host ""
Write-Host "[2/2] Starting web server on http://localhost:5000 ..." -ForegroundColor Green
Write-Host "Press Ctrl+C in this terminal to stop the server." -ForegroundColor Gray
Write-Host ""

Start-Process "http://localhost:5000"
python app.py
