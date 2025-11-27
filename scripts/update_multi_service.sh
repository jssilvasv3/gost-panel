#!/bin/bash
# ============================================================
# Script de Atualização - Multi-Service Config Generation
# ============================================================

echo "============================================================"
echo "  Atualizando Painel GOST - Multi-Service Support"
echo "============================================================"
echo ""

# Parar painel
echo "[1/4] Parando painel..."
sudo systemctl stop gost-panel

# Copiar novo app.py
echo "[2/4] Atualizando app.py..."
sudo cp /root/gost_update/panel/app.py /opt/gost-panel/

# Corrigir permissões
echo "[3/4] Corrigindo permissões..."
sudo chown -R gostsvc:gostsvc /opt/gost-panel

# Reiniciar painel
echo "[4/4] Reiniciando painel..."
sudo systemctl start gost-panel

echo ""
echo "============================================================"
echo "  ✅ Atualização Concluída!"
echo "============================================================"
echo ""
echo "📋 Novos Recursos:"
echo ""
echo "✅ Geração automática de configs para:"
echo "   - GOST (SOCKS5, HTTP, TCP, UDP)"
echo "   - Shadowsocks-libev (SS)"
echo "   - Xray (VMess, VLESS, Trojan)"
echo ""
echo "✅ Ao clicar 'Aplicar Configuração':"
echo "   - Lê regras do banco"
echo "   - Agrupa por protocolo"
echo "   - Gera configs automaticamente"
echo "   - Reinicia serviços necessários"
echo ""
echo "============================================================"
echo "🔍 Verificar status:"
echo "   sudo systemctl status gost-panel"
echo ""
echo "📱 Testar:"
echo "   1. Crie regras no painel"
echo "   2. Clique em 'Aplicar Configuração'"
echo "   3. Verifique serviços reiniciados"
echo "============================================================"
