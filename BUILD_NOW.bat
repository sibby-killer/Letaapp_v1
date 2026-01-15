@echo off
echo.
echo ================================================================
echo    LETA APP - FINAL BUILD SCRIPT
echo ================================================================
echo.
echo Cleaning project...
call flutter clean
echo.
echo Getting dependencies...
call flutter pub get
echo.
echo Building and running app...
call flutter run
echo.
echo ================================================================
echo    BUILD COMPLETE!
echo ================================================================
echo.
pause
