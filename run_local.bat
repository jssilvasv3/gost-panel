@echo off
REM ============================================================
REM GOST Panel - Run Local Development Server
REM ============================================================

REM Navigate to panel directory
cd /d "%~dp0panel"

REM Check if virtual environment exists
if not exist venv (
    echo.
    echo [ERRO] Ambiente virtual nao encontrado!
    echo Por favor, execute setup_local.bat primeiro.
    echo.
    pause
    exit /b 1
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Check if app_local.py exists
if not exist app_local.py (
    echo.
    echo [ERRO] app_local.py nao encontrado!
    echo.
    pause
    exit /b 1
)

REM Display startup message
echo.
echo ============================================================
echo    GOST Panel - Servidor Local de Desenvolvimento
echo ============================================================
echo.
echo Iniciando servidor Flask...
echo.
echo Credenciais padrao:
echo     Usuario: admin
echo     Senha: admin
echo.
echo O navegador sera aberto automaticamente em:
echo     http://localhost:5000
echo.
echo Pressione Ctrl+C para parar o servidor.
echo ============================================================
echo.

REM Wait a moment then open browser
start "" timeout /t 3 /nobreak >nul 2>&1 && start http://localhost:5000

REM Run the Flask app
python app_local.py

REM Deactivate virtual environment on exit
deactivate
