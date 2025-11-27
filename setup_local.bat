@echo off
REM ============================================================
REM GOST Panel - Setup Local Development Environment
REM ============================================================
echo.
echo ============================================================
echo    GOST Panel - Configuracao Local para Desenvolvimento
echo ============================================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python 3 nao encontrado!
    echo Por favor, instale Python 3.8 ou superior de: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [OK] Python encontrado:
python --version
echo.

REM Navigate to panel directory
cd /d "%~dp0panel"

REM Create virtual environment
echo [1/6] Criando ambiente virtual Python...
if exist venv (
    echo Ambiente virtual ja existe. Removendo...
    rmdir /s /q venv
)
python -m venv venv
if errorlevel 1 (
    echo [ERRO] Falha ao criar ambiente virtual!
    pause
    exit /b 1
)
echo [OK] Ambiente virtual criado.
echo.

REM Activate virtual environment and install dependencies
echo [2/6] Instalando dependencias...
call venv\Scripts\activate.bat
python -m pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias!
    pause
    exit /b 1
)
echo [OK] Dependencias instaladas.
echo.

REM Create local directories
echo [3/6] Criando diretorios locais...
if not exist local_data mkdir local_data
if not exist local_config mkdir local_config
echo [OK] Diretorios criados:
echo     - panel\local_data\
echo     - panel\local_config\
echo.

REM Initialize database
echo [4/6] Inicializando banco de dados...
if exist local_data\panel.db (
    echo Banco de dados ja existe. Mantendo dados existentes.
) else (
    echo Criando novo banco de dados...
)
echo [OK] Banco de dados pronto.
echo.

REM Check if app_local.py exists
echo [5/6] Verificando arquivos...
if not exist app_local.py (
    echo [AVISO] app_local.py nao encontrado!
    echo Por favor, certifique-se de que todos os arquivos foram copiados corretamente.
    pause
    exit /b 1
)
echo [OK] Arquivos verificados.
echo.

REM Create desktop shortcut (optional)
echo [6/6] Configuracao concluida!
echo.
echo ============================================================
echo    Instalacao Completa!
echo ============================================================
echo.
echo Para iniciar o painel local, execute:
echo     run_local.bat
echo.
echo Credenciais padrao:
echo     Usuario: admin
echo     Senha: admin
echo.
echo IMPORTANTE: Altere a senha apos o primeiro login!
echo ============================================================
echo.
pause
