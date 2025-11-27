@echo off
REM ============================================================
REM Script de Upload Limpo para VPS - Apenas arquivos essenciais
REM ============================================================

echo.
echo ============================================================
echo   Preparando Upload Limpo para VPS
echo ============================================================
echo.

cd /d "%~dp0gost_full_package"

REM Criar diretório temporário para arquivos essenciais
set TEMP_DIR=..\gost_vps_clean
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

echo [1/4] Copiando arquivos essenciais...

REM Copiar arquivos principais
copy install.sh "%TEMP_DIR%\" >nul
copy LICENSE "%TEMP_DIR%\" >nul
copy README.md "%TEMP_DIR%\" >nul

REM Copiar diretórios necessários
echo   - Panel...
xcopy /E /I /Q panel "%TEMP_DIR%\panel" >nul

echo   - Scripts...
xcopy /E /I /Q scripts "%TEMP_DIR%\scripts" >nul

echo   - Systemd...
xcopy /E /I /Q systemd "%TEMP_DIR%\systemd" >nul

echo   - Examples...
xcopy /E /I /Q examples "%TEMP_DIR%\examples" >nul

REM Limpar arquivos desnecessários do panel
echo [2/4] Removendo arquivos de desenvolvimento...
if exist "%TEMP_DIR%\panel\local_data" rmdir /s /q "%TEMP_DIR%\panel\local_data"
if exist "%TEMP_DIR%\panel\local_config" rmdir /s /q "%TEMP_DIR%\panel\local_config"
if exist "%TEMP_DIR%\panel\__pycache__" rmdir /s /q "%TEMP_DIR%\panel\__pycache__"
if exist "%TEMP_DIR%\panel\routes\__pycache__" rmdir /s /q "%TEMP_DIR%\panel\routes\__pycache__"
if exist "%TEMP_DIR%\panel\*.pyc" del /q "%TEMP_DIR%\panel\*.pyc"
if exist "%TEMP_DIR%\panel\app_local.py" del /q "%TEMP_DIR%\panel\app_local.py"

echo [OK] Arquivos limpos!
echo.

echo [3/4] Comprimindo pacote limpo...
cd ..
powershell -Command "Compress-Archive -Path 'gost_vps_clean' -DestinationPath 'gost_vps_clean.zip' -Force"

if %errorlevel% neq 0 (
    echo [ERRO] Falha ao comprimir
    pause
    exit /b 1
)

echo [OK] Pacote criado: gost_vps_clean.zip
echo.

echo [4/4] Fazendo upload para VPS...
echo IP: 143.110.239.145
echo.
echo Digite a senha do root quando solicitado:
echo.

scp gost_vps_clean.zip root@143.110.239.145:/root/

if %errorlevel% neq 0 (
    echo.
    echo [ERRO] Falha no upload
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   Upload Concluido com Sucesso!
echo ============================================================
echo.
echo Arquivos enviados (apenas essenciais):
echo   - install.sh
echo   - panel/ (app.py, templates, routes, static)
echo   - scripts/
echo   - systemd/
echo   - examples/
echo.
echo Arquivos NAO enviados (desenvolvimento):
echo   - app_local.py
echo   - local_data/
echo   - local_config/
echo   - venv/
echo   - __pycache__/
echo   - README_LOCAL.md
echo   - setup_local.bat
echo   - run_local.bat
echo.

echo Proximos passos na VPS:
echo.
echo 1. Conectar via SSH:
echo    ssh root@143.110.239.145
echo.
echo 2. Descompactar e instalar:
echo    cd /root
echo    unzip gost_vps_clean.zip
echo    cd gost_vps_clean
echo    sudo bash install.sh --domain seu.dominio.com --email seu@email.com
echo.
echo ============================================================
echo   Deseja conectar na VPS agora? (S/N)
echo ============================================================
set /p CONNECT="Resposta: "

if /i "%CONNECT%"=="S" (
    echo.
    echo Conectando...
    ssh root@143.110.239.145
) else (
    echo.
    echo OK! Conecte-se manualmente quando estiver pronto.
)

REM Limpar diretório temporário
echo.
echo Limpando arquivos temporarios...
rmdir /s /q "%TEMP_DIR%"
del /q gost_vps_clean.zip

echo.
echo Concluido!
pause
