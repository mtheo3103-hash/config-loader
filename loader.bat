@echo off
title Config Loader
chcp 65001 >nul

:: =====================================================
:: 1) COPYRIGHT SCREEN (3 seconds)
:: =====================================================
cls
echo Config Loader, Copyright mtheo3103
timeout /t 3 >nul

:: =====================================================
:: 2) INITIALIZING + LOADING BAR
:: =====================================================
set "bar="
for /l %%i in (1,1,20) do (
    set "bar=#%bar%"
    cls
    echo Initializing...
    echo [%bar%]
    ping localhost -n 2 >nul
)

:: =====================================================
:: 3) UPDATE CHECK
:: =====================================================
cls
echo Checking for updates...
echo.

set "localVersion=1.0"
set "versionUrl=https://raw.githubusercontent.com/mtheo3103-hash/config-loader/main/latest-version.txt"

curl -L --ssl-no-revoke -s "%versionUrl%" -o "%~dp0latest_version.txt"

if exist "%~dp0latest_version.txt" (
    set /p latestVersion=<"%~dp0latest_version.txt"
    del "%~dp0latest_version.txt"

    if not "%localVersion%"=="%latestVersion%" (
        cls
        echo Update Available!
        timeout /t 4 >nul
    )
) else (
    echo Could not check for updates.
    timeout /t 2 >nul
)

goto menu

:: =====================================================
:: 4) MAIN MENU
:: =====================================================
:menu
cls
echo ================================
echo        Configs for Rise
echo ================================
echo.
echo  1. Polar
echo  2. Mineblaze
echo  3. NewBlocksMC
echo  4. Exit
echo.
set /p "choice=Select an option: "

if "%choice%"=="1" goto polar
if "%choice%"=="2" goto mineblaze
if "%choice%"=="3" goto newblocks
if "%choice%"=="4" exit /b
goto menu

:: =====================================================
:: 5) CONFIG DEFINITIONS
:: =====================================================

:polar
set "name=Polar"
set "url=https://raw.githubusercontent.com/mtheo3103-hash/config-loader/main/configs/polar.enc"
set "password=weky12ibpasd24"
goto process

:mineblaze
set "name=Mineblaze"
set "url=https://raw.githubusercontent.com/mtheo3103-hash/config-loader/main/configs/mineblaze.enc"
set "password=weky12ibpasd24"
goto process

:newblocks
set "name=NewBlocksMC"
set "url=https://raw.githubusercontent.com/mtheo3103-hash/config-loader/main/configs/newblocks.enc"
set "password=weky12ibpasd24"
goto process

:: =====================================================
:: 6) PROCESSING BLOCK (DOWNLOAD + DECRYPT)
:: =====================================================
:process
cls
echo Processing %name%...
echo.

set "encDir=%~dp0encrypted-configs"
set "decDir=%~dp0decrypted-configs"

if not exist "%encDir%" mkdir "%encDir%"
if not exist "%decDir%" mkdir "%decDir%"

set "encFile=%encDir%\%name%.enc"
set "decFile=%decDir%\%name%.json"

echo Downloading encrypted file...
curl -L --ssl-no-revoke -s "%url%" -o "%encFile%"

if not exist "%encFile%" (
    echo [!] Download failed.
    pause
    goto menu
)

echo Decrypting...
powershell -Command ^
    "$Password='%password%';" ^
    "$Salt=[byte[]](1..16);" ^
    "$Key=(New-Object Security.Cryptography.Rfc2898DeriveBytes $Password,$Salt,1000).GetBytes(32);" ^
    "$Data=[System.IO.File]::ReadAllBytes('%encFile%');" ^
    "$IV=$Data[0..15];" ^
    "$AES=New-Object System.Security.Cryptography.AesManaged;" ^
    "$AES.Key=$Key; $AES.IV=$IV;" ^
    "$Decryptor=$AES.CreateDecryptor();" ^
    "$Decrypted=$Decryptor.TransformFinalBlock($Data,16,$Data.Length-16);" ^
    "[System.IO.File]::WriteAllBytes('%decFile%',$Decrypted)"

if not exist "%decFile%" (
    echo [!] Decryption failed.
    pause
    goto menu
)

echo.
echo [✓] %name% successfully decrypted!
echo Saved in:
echo %decFile%
echo.
pause
goto menu