# ============================================
# Script PowerShell - Exécution tests BDD
# MyGameList - PostgreSQL
# ============================================

# Fix UTF-8 encoding pour PowerShell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TESTS BASE DE DONNEES - MyGameList" -ForegroundColor Cyan
Write-Host "  PostgreSQL 16" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verifier si Docker est en cours d'execution
Write-Host "Verification de Docker..." -ForegroundColor Yellow
$dockerRunning = docker info 2>$null
if (-not $dockerRunning) {
    Write-Host "[ERREUR] Docker n'est pas en cours d'execution" -ForegroundColor Red
    Write-Host "         Lancez Docker Desktop et reessayez" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Docker est actif" -ForegroundColor Green
Write-Host ""

# Verifier si le conteneur PostgreSQL existe
Write-Host "Verification du conteneur PostgreSQL..." -ForegroundColor Yellow
$postgresContainer = docker ps -a --filter "name=mygamelist-postgres-dev" --format "{{.Names}}" 2>$null

if (-not $postgresContainer) {
    Write-Host "[INFO] Conteneur PostgreSQL non trouve" -ForegroundColor Yellow
    Write-Host "       Lancement de docker-compose..." -ForegroundColor Yellow
    docker-compose -f docker-compose.dev.yml up -d postgres

    Write-Host "[WAIT] Attente du demarrage de PostgreSQL (30s)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# Verifier si le conteneur est demarre
$postgresRunning = docker ps --filter "name=mygamelist-postgres-dev" --format "{{.Names}}" 2>$null
if (-not $postgresRunning) {
    Write-Host "[INFO] PostgreSQL n'est pas demarre, demarrage..." -ForegroundColor Yellow
    docker start mygamelist-postgres-dev

    Write-Host "[WAIT] Attente du demarrage (20s)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 20
}

Write-Host "[OK] Conteneur PostgreSQL pret" -ForegroundColor Green
Write-Host ""

# Executer les tests
Write-Host "Execution des tests SQL..." -ForegroundColor Cyan
Write-Host ""

$testFile = "tests/database/test-all-triggers.sql"
if (-not (Test-Path $testFile)) {
    Write-Host "[ERREUR] Fichier de test introuvable: $testFile" -ForegroundColor Red
    exit 1
}

# Executer via Docker (PostgreSQL)
Get-Content $testFile | docker exec -i mygamelist-postgres-dev psql -U dev_user -d mygamelist_dev

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TESTS TERMINES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Les resultats sont affiches avec RAISE NOTICE" -ForegroundColor Yellow
Write-Host "  [OK] PASS = Test reussi" -ForegroundColor Green
Write-Host "  [KO] FAIL = Test echoue" -ForegroundColor Red
