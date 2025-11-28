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

# Compter les tests
$triggerTests = Get-ChildItem -Path "tests/database/triggers" -Filter "*.sql" -ErrorAction SilentlyContinue
$viewTests = Get-ChildItem -Path "tests/database/views" -Filter "*.sql" -ErrorAction SilentlyContinue
$totalTests = ($triggerTests.Count + $viewTests.Count)

Write-Host "[INFO] Tests de triggers trouves: $($triggerTests.Count)" -ForegroundColor Yellow
Write-Host "[INFO] Tests de vues trouves: $($viewTests.Count)" -ForegroundColor Yellow
Write-Host "[INFO] Total de fichiers de tests: $totalTests" -ForegroundColor Yellow
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Executer les tests de triggers
if ($triggerTests.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  TESTS DES TRIGGERS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($testFile in $triggerTests) {
        Write-Host "Execution: $($testFile.Name)" -ForegroundColor Yellow
        $result = Get-Content $testFile.FullName | docker exec -i mygamelist-postgres-dev psql -U dev_user -d mygamelist 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $testsPassed++
            Write-Host "[OK] $($testFile.Name) termine" -ForegroundColor Green
        } else {
            $testsFailed++
            Write-Host "[KO] $($testFile.Name) echoue" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Executer les tests de vues
if ($viewTests.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  TESTS DES VUES" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($testFile in $viewTests) {
        Write-Host "Execution: $($testFile.Name)" -ForegroundColor Yellow
        $result = Get-Content $testFile.FullName | docker exec -i mygamelist-postgres-dev psql -U dev_user -d mygamelist 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $testsPassed++
            Write-Host "[OK] $($testFile.Name) termine" -ForegroundColor Green
        } else {
            $testsFailed++
            Write-Host "[KO] $($testFile.Name) echoue" -ForegroundColor Red
        }
        Write-Host ""
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESUME DES TESTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total: $totalTests fichiers" -ForegroundColor White
Write-Host "Reussis: $testsPassed" -ForegroundColor Green
Write-Host "Echoues: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Les resultats detailles sont affiches avec RAISE NOTICE" -ForegroundColor Yellow
Write-Host "  [PASS] = Test reussi" -ForegroundColor Green
Write-Host "  [FAIL] = Test echoue" -ForegroundColor Red
