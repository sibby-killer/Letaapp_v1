@echo off
cls
echo.
echo ================================================================
echo    LETA APP - SIMPLE BUILD SCRIPT
echo ================================================================
echo.
echo This will build your APK without Android Studio
echo.
pause

echo.
echo [1/4] Killing any stuck processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM studio64.exe 2>nul
taskkill /F /IM gradle.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/4] Cleaning project...
call flutter clean

echo.
echo [3/4] Getting dependencies...
call flutter pub get

echo.
echo [4/4] Building APK (this takes 5-10 minutes)...
call flutter build apk --release

echo.
echo ================================================================
echo    BUILD COMPLETE!
echo ================================================================
echo.
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo SUCCESS! Your APK is ready at:
    echo build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo APK Size:
    dir "build\app\outputs\flutter-apk\app-release.apk" | find "app-release.apk"
    echo.
    echo Next steps:
    echo 1. Copy APK to your phone
    echo 2. Install it
    echo 3. Test the app
    echo 4. Push to GitHub
) else (
    echo ERROR: Build failed! Check the error messages above.
)
echo.
echo ================================================================
pause
