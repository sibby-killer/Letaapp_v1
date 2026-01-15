# Leta App - Automated Build Script (PowerShell)
# Run this script after applying all fixes

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   🚀 LETA APP - BUILD SCRIPT" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Flutter
Write-Host "📋 [1/6] Checking Flutter installation..." -ForegroundColor Yellow
$flutter = Get-Command flutter -ErrorAction SilentlyContinue

if ($null -eq $flutter) {
    Write-Host "❌ ERROR: Flutter not found!" -ForegroundColor Red
    Write-Host "   Please install Flutter from: https://flutter.dev" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Flutter found at: $($flutter.Source)" -ForegroundColor Green
Write-Host ""

# Step 2: Check Flutter Version
Write-Host "📋 [2/6] Verifying Flutter version..." -ForegroundColor Yellow
$flutterVersion = flutter --version | Select-String "Flutter" | Out-String
Write-Host $flutterVersion -ForegroundColor Gray

if ($flutterVersion -match "Flutter (\d+)\.(\d+)\.(\d+)") {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    
    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 16)) {
        Write-Host "⚠️  WARNING: Flutter version should be 3.16.0 or higher" -ForegroundColor Yellow
        Write-Host "   Run: flutter upgrade" -ForegroundColor Yellow
        $response = Read-Host "   Continue anyway? (y/n)"
        if ($response -ne 'y') {
            exit 1
        }
    }
}
Write-Host "✅ Flutter version OK" -ForegroundColor Green
Write-Host ""

# Step 3: Clean Project
Write-Host "📋 [3/6] Cleaning project..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Clean complete" -ForegroundColor Green
}
else {
    Write-Host "❌ ERROR: Clean failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Get Dependencies
Write-Host "📋 [4/6] Installing dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
}
else {
    Write-Host "❌ ERROR: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Run Analyzer
Write-Host "📋 [5/6] Running analyzer..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos --no-fatal-warnings
Write-Host ""

# Step 6: Check Device
Write-Host "📋 [6/6] Checking for connected devices..." -ForegroundColor Yellow
flutter devices
Write-Host ""

# Summary
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   ✅ SETUP COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Connect your Android device via USB" -ForegroundColor White
Write-Host "2. Enable USB Debugging on your device" -ForegroundColor White
Write-Host "3. Run one of these commands:" -ForegroundColor White
Write-Host ""
Write-Host "   flutter run              " -ForegroundColor Cyan -NoNewline
Write-Host "(debug build)" -ForegroundColor Gray
Write-Host "   flutter run --release    " -ForegroundColor Cyan -NoNewline
Write-Host "(release build)" -ForegroundColor Gray
Write-Host "   flutter build apk        " -ForegroundColor Cyan -NoNewline
Write-Host "(build APK file)" -ForegroundColor Gray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
