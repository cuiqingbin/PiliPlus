@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

if /i "%~1"=="--no-pause" set "NO_PAUSE=1"

cd /d "%~dp0"

if not exist "pubspec.yaml" (
    echo [ERROR] 请从项目根目录运行该脚本。
    goto :fail
)
if not exist "pili_release.json" (
    echo [ERROR] 缺少 pili_release.json，Release 必须使用发布配置。
    goto :fail
)

set "FLUTTER="
for /f "delims=" %%I in ('where flutter.bat 2^>nul') do (
    set "FLUTTER=%%I"
    goto :flutter_ok
)
for /f "delims=" %%I in ('where flutter 2^>nul') do (
    set "FLUTTER=%%I"
    goto :flutter_ok
)
:flutter_ok
if not defined FLUTTER if exist "android\local.properties" (
    for /f "usebackq tokens=1,* delims==" %%A in ("android\local.properties") do (
        if /i "%%A"=="flutter.sdk" set "FLUTTER_SDK=%%B"
    )
    if defined FLUTTER_SDK (
        set "FLUTTER_SDK=!FLUTTER_SDK:\\=\!"
        if exist "!FLUTTER_SDK!\bin\flutter.bat" set "FLUTTER=!FLUTTER_SDK!\bin\flutter.bat"
    )
)
if not defined FLUTTER (
    echo [ERROR] 找不到 Flutter，请加入 PATH 或在 android\local.properties 设置 flutter.sdk。
    goto :fail
)

if exist "%USERPROFILE%\.jdks\corretto-21.0.11\bin\java.exe" (
    set "JAVA_HOME=%USERPROFILE%\.jdks\corretto-21.0.11"
    set "PATH=!JAVA_HOME!\bin;!PATH!"
) else if exist "C:\Program Files\JetBrains\IntelliJ IDEA 2025.3.2\jbr\bin\java.exe" (
    set "JAVA_HOME=C:\Program Files\JetBrains\IntelliJ IDEA 2025.3.2\jbr"
    set "PATH=!JAVA_HOME!\bin;!PATH!"
)

echo Building PiliPlus APK (Release arm64-v8a)
echo Flutter: !FLUTTER!
if defined JAVA_HOME echo JDK: !JAVA_HOME!
echo.

call "!FLUTTER!" build apk --release --target-platform android-arm64 --split-per-abi --dart-define-from-file=pili_release.json --no-pub
set "BUILD_ERR=!errorlevel!"
if not "!BUILD_ERR!"=="0" (
    echo [ERROR] 构建失败。
    goto :fail
)

set "APK=%CD%\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
if not exist "!APK!" (
    echo [ERROR] 找不到 APK: !APK!
    goto :fail
)

for %%F in ("!APK!") do set /a "APK_MB=%%~zF / 1048576"
echo.
echo [SUCCESS] !APK!
echo Size: !APK_MB! MB
echo.
if not defined NO_PAUSE pause
exit /b 0

:fail
if not defined NO_PAUSE pause
exit /b 1