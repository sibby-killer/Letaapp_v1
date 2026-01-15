@echo off
echo.
echo ================================================================
echo    PUSHING LETA APP TO GITHUB
echo ================================================================
echo.
echo This will push all changes to: https://github.com/sibby-killer/Letaapp_v1.git
echo.
pause
echo.
echo Adding all files...
git add .
echo.
echo Committing changes...
git commit -m "Production ready - Supabase Realtime, all features complete, ready to build"
echo.
echo Pushing to GitHub...
git push origin main
echo.
echo ================================================================
echo    PUSH COMPLETE!
echo ================================================================
echo.
echo Next steps:
echo 1. Build APK: flutter build apk --release
echo 2. Go to: https://github.com/sibby-killer/Letaapp_v1/releases
echo 3. Create new release and upload APK
echo.
pause
