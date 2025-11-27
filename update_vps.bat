@echo off
REM ============================================================
REM Script de Atualização Rápida - Upload para VPS
REM ============================================================

echo.
echo ============================================================
echo   Atualizacao Rapida do Painel GOST
echo ============================================================
echo.

cd /d "%~dp0gost_full_package"

echo [1/3] Criando pacote de atualizacao...

REM Criar diretório temporário
set UPDATE_DIR=..\gost_update
if exist "%UPDATE_DIR%" rmdir /s /q "%UPDATE_DIR%"
mkdir "%UPDATE_DIR%"
mkdir "%UPDATE_DIR%\panel"
mkdir "%UPDATE_DIR%\panel\templates"
mkdir "%UPDATE_DIR%\panel\routes"

REM Copiar apenas arquivos modificados
echo   - app.py
copy panel\app.py "%UPDATE_DIR%\panel\" >nul

echo   - requirements.txt
copy panel\requirements.txt "%UPDATE_DIR%\panel\" >nul

echo   - Templates
copy panel\templates\index.html "%UPDATE_DIR%\panel\templates\" >nul
copy panel\templates\edit_user.html "%UPDATE_DIR%\panel\templates\" >nul
copy panel\templates\nodes.html "%UPDATE_DIR%\panel\templates\" >nul
copy panel\templates\create_node.html "%UPDATE_DIR%\panel\templates\" >nul

echo   - Routes
copy panel\routes\api.py "%UPDATE_DIR%\panel\routes\" >nul

REM Criar script de atualização para VPS
echo #!/bin/bash > "%UPDATE_DIR%\update.sh"
echo # Script de Atualizacao Automatica >> "%UPDATE_DIR%\update.sh"
echo echo "Parando servico..." >> "%UPDATE_DIR%\update.sh"
echo sudo systemctl stop gost-panel >> "%UPDATE_DIR%\update.sh"
echo. >> "%UPDATE_DIR%\update.sh"
echo echo "Copiando arquivos..." >> "%UPDATE_DIR%\update.sh"
echo sudo cp panel/app.py /opt/gost-panel/ >> "%UPDATE_DIR%\update.sh"
echo sudo cp panel/requirements.txt /opt/gost-panel/ >> "%UPDATE_DIR%\update.sh"
echo sudo cp panel/templates/*.html /opt/gost-panel/templates/ >> "%UPDATE_DIR%\update.sh"
echo sudo cp panel/routes/api.py /opt/gost-panel/routes/ >> "%UPDATE_DIR%\update.sh"
echo. >> "%UPDATE_DIR%\update.sh"
echo echo "Instalando dependencias..." >> "%UPDATE_DIR%\update.sh"
echo sudo -u gostsvc /opt/gost-panel/venv/bin/pip install -r /opt/gost-panel/requirements.txt >> "%UPDATE_DIR%\update.sh"
echo. >> "%UPDATE_DIR%\update.sh"
echo echo "Corrigindo permissoes..." >> "%UPDATE_DIR%\update.sh"
echo sudo chown -R gostsvc:gostsvc /opt/gost-panel >> "%UPDATE_DIR%\update.sh"
echo. >> "%UPDATE_DIR%\update.sh"
echo echo "Reiniciando servico..." >> "%UPDATE_DIR%\update.sh"
echo sudo systemctl start gost-panel >> "%UPDATE_DIR%\update.sh"
echo. >> "%UPDATE_DIR%\update.sh"
echo echo "Verificando status..." >> "%UPDATE_DIR%\update.sh"
echo sudo systemctl status gost-panel >> "%UPDATE_DIR%\update.sh"
echo. >> "%UPDATE_DIR%\update.sh"
echo echo "Atualizacao concluida!" >> "%UPDATE_DIR%\update.sh"

echo [OK] Pacote criado!
echo.

echo [2/3] Comprimindo...
cd ..
powershell -Command "Compress-Archive -Path 'gost_update' -DestinationPath 'gost_update.zip' -Force"

echo [OK] Arquivo: gost_update.zip
echo.

echo [3/3] Fazendo upload para VPS...
echo IP: 138.197.212.221
echo.

scp gost_update.zip root@138.197.212.221:/root/

if %errorlevel% neq 0 (
    echo.
    echo [ERRO] Falha no upload
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   Upload Concluido!
echo ============================================================
echo.
echo Proximos passos na VPS:
echo.
echo 1. Conectar via SSH:
echo    ssh root@138.197.212.221
echo.
echo 2. Executar atualizacao:
echo    cd /root
echo    unzip -o gost_update.zip
echo    cd gost_update
echo    chmod +x update.sh
echo    sudo bash update.sh
echo.
echo ============================================================
echo   Deseja conectar na VPS agora? (S/N)
echo ============================================================
set /p CONNECT="Resposta: "

if /i "%CONNECT%"=="S" (
    echo.
    echo Conectando...
    ssh root@138.197.212.221
)

echo.
echo Limpando arquivos temporarios...
rmdir /s /q "%UPDATE_DIR%"
del /q gost_update.zip

echo.
echo Concluido!
pause
