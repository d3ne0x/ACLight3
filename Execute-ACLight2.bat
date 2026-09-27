@echo off
setlocal
cd /d "%~dp0"

echo.
echo  ACLight3 - Privileged Account and Shadow Admin Analysis
echo.

powershell.exe -NoLogo -NoProfile -File "%~dp0Start-ACLight3.ps1" %*
set "exitCode=%ERRORLEVEL%"

echo.
if not "%exitCode%"=="0" (
    echo ACLight3 finished with errors. Exit code: %exitCode%
) else (
    echo ACLight3 completed successfully.
)
pause
exit /b %exitCode%
