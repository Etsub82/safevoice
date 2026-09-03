@echo off
REM SafeVoice APK Build Script
REM Usage: build_apk.bat [API_URL]
REM Example: build_apk.bat https://safevoice-api.onrender.com

SET API_URL=%1
IF "%API_URL%"=="" SET API_URL=https://safevoice-api.onrender.com

echo Building SafeVoice APK...
echo API URL: %API_URL%

flutter build apk --release --dart-define=API_BASE_URL=%API_URL%

echo.
echo Done! APK is at: build\app\outputs\flutter-apk\app-release.apk
