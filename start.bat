@echo off
setlocal enabledelayedexpansion

if not exist "mgr\server.py" (
    echo ERROR: Run this from the project root (where mgr\server.py lives)
    exit /b 1
)

echo Starting Alfresco Control Plane...

REM Kill any previous instance listening on port 9700
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":9700"') do (
    taskkill /F /PID %%a >nul 2>&1
    if !errorlevel! equ 0 (
        timeout /t 1 /nobreak >nul
    )
)

start /B python mgr\server.py

echo|set /p="Waiting for server"
for /l %%i in (1,1,30) do (
    >nul 2>&1 curl -sf http://localhost:9700 && (
        echo  ready.
        start http://localhost:9700
        goto :wait
    )
    echo|set /p="."
    timeout /t 1 /nobreak >nul
)
echo.
echo Timed out waiting for server.
exit /b 1

:wait
echo Press Ctrl+C to stop the server.
pause >nul
