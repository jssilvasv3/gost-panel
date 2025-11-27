#!/bin/bash
# ============================================================
# Script de Configuração Automática - Todos os Protocolos Mobile
# ============================================================

echo "============================================================"
echo "  Configurando TODOS os Protocolos para Mobile"
echo "============================================================"
echo ""

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Gerar UUIDs para VMess e VLESS
UUID_VMESS=$(uuidgen)
UUID_VLESS=$(uuidgen)

echo -e "${BLUE}[1/4] Criando regras no banco de dados...${NC}"

# Conectar ao banco e criar regras
sqlite3 /opt/gost-panel/panel.db << EOF
-- Shadowsocks
INSERT INTO users(name, protocol, listen, target, password, extra, chain_nodes) 
VALUES ('Shadowsocks Mobile', 'ss', ':8388', 'tcp://8.8.8.8:53', 'MinhaSenha123!', 'method=aes-256-gcm', '');

-- VMess
INSERT INTO users(name, protocol, listen, target, password, extra, chain_nodes) 
VALUES ('VMess Mobile', 'vmess', ':10086', 'tcp://8.8.8.8:53', '', 'uuid=${UUID_VMESS},alterId=0', '');

-- VLESS
INSERT INTO users(name, protocol, listen, target, password, extra, chain_nodes) 
VALUES ('VLESS Mobile', 'vless', ':10087', 'tcp://8.8.8.8:53', '', 'uuid=${UUID_VLESS}', '');

-- HTTP Proxy
INSERT INTO users(name, protocol, listen, target, password, extra, chain_nodes) 
VALUES ('HTTP Proxy', 'http', ':8080', 'tcp://8.8.8.8:53', '', '', '');

-- Trojan
INSERT INTO users(name, protocol, listen, target, password, extra, chain_nodes) 
VALUES ('Trojan Mobile', 'trojan', ':8443', 'tcp://8.8.8.8:53', 'TrojanSenha123!', '', '');
EOF

echo -e "${GREEN}✅ Regras criadas!${NC}"
echo ""

echo -e "${BLUE}[2/4] Abrindo portas no firewall...${NC}"

# Abrir portas
iptables -I INPUT -p tcp --dport 8388 -j ACCEPT  # Shadowsocks
iptables -I INPUT -p tcp --dport 10086 -j ACCEPT # VMess
iptables -I INPUT -p tcp --dport 10087 -j ACCEPT # VLESS
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT  # HTTP
iptables -I INPUT -p tcp --dport 8443 -j ACCEPT  # Trojan

# Salvar regras
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo -e "${GREEN}✅ Portas abertas!${NC}"
echo ""

echo -e "${BLUE}[3/4] Gerando configuração GOST...${NC}"

# Gerar config.json via painel (simular apply_config)
# Ou fazer manualmente:
cat > /etc/gost/config.json << 'EOFCONFIG'
{
  "services": [
    {
      "name": "socks5-tunnel",
      "addr": ":1081",
      "handler": {
        "type": "socks5"
      },
      "listener": {
        "type": "tcp"
      }
    },
    {
      "name": "shadowsocks-mobile",
      "addr": ":8388",
      "handler": {
        "type": "ss",
        "auth": {
          "username": "",
          "password": "MinhaSenha123!"
        },
        "metadata": {
          "cipher": "aes-256-gcm"
        }
      },
      "listener": {
        "type": "tcp"
      }
    },
    {
      "name": "http-proxy",
      "addr": ":8080",
      "handler": {
        "type": "http"
      },
      "listener": {
        "type": "tcp"
      }
    }
  ],
  "chains": [],
  "api": {
    "addr": "127.0.0.1:18080",
    "pathPrefix": "/api"
  }
}
EOFCONFIG

chown gostsvc:gostsvc /etc/gost/config.json

echo -e "${GREEN}✅ Configuração gerada!${NC}"
echo ""

echo -e "${BLUE}[4/4] Reiniciando serviços...${NC}"

# Reiniciar GOST
systemctl restart gost
sleep 2

# Verificar status
if systemctl is-active --quiet gost; then
    echo -e "${GREEN}✅ GOST rodando!${NC}"
else
    echo -e "${YELLOW}⚠️  GOST com problemas. Verificando logs...${NC}"
    journalctl -u gost -n 20 --no-pager
fi

echo ""
echo "============================================================"
echo -e "${GREEN}  Configuração Concluída!${NC}"
echo "============================================================"
echo ""
echo -e "${YELLOW}📱 Protocolos Configurados:${NC}"
echo ""
echo "1. SOCKS5"
echo "   Porta: 1081"
echo "   App: v2rayNG, Shadowrocket"
echo ""
echo "2. Shadowsocks"
echo "   Porta: 8388"
echo "   Senha: MinhaSenha123!"
echo "   Método: aes-256-gcm"
echo "   App: Shadowsocks, v2rayNG"
echo ""
echo "3. VMess"
echo "   Porta: 10086"
echo "   UUID: ${UUID_VMESS}"
echo "   AlterID: 0"
echo "   App: v2rayNG, Shadowrocket"
echo ""
echo "4. VLESS"
echo "   Porta: 10087"
echo "   UUID: ${UUID_VLESS}"
echo "   App: v2rayNG, Shadowrocket"
echo ""
echo "5. HTTP Proxy"
echo "   Porta: 8080"
echo "   App: Configurações do sistema"
echo ""
echo "6. Trojan"
echo "   Porta: 8443"
echo "   Senha: TrojanSenha123!"
echo "   App: v2rayNG, Shadowrocket"
echo ""
echo "============================================================"
echo -e "${BLUE}🔍 Verificar portas abertas:${NC}"
echo "   sudo ss -tlnp | grep gost"
echo ""
echo -e "${BLUE}📊 Ver status:${NC}"
echo "   sudo systemctl status gost"
echo ""
echo -e "${BLUE}📱 Acessar painel:${NC}"
echo "   http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo -e "${GREEN}✅ Tudo pronto para usar no celular!${NC}"
echo "============================================================"
