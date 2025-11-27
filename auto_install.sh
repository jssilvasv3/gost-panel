#!/bin/bash

#############################################
# GOST Panel - Auto Installer
# Instalação completa e automática
# Ubuntu 20.04/22.04 LTS
#############################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ██████╗  ██████╗ ███████╗████████╗                     ║
║  ██╔════╝ ██╔═══██╗██╔════╝╚══██╔══╝                     ║
║  ██║  ███╗██║   ██║███████╗   ██║                        ║
║  ██║   ██║██║   ██║╚════██║   ██║                        ║
║  ╚██████╔╝╚██████╔╝███████║   ██║                        ║
║   ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝                        ║
║                                                           ║
║         PAINEL DE GERENCIAMENTO COMPLETO                 ║
║              Auto Installer v2.0                         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}Instalação Automática do GOST Panel${NC}"
echo -e "${YELLOW}Este script vai instalar:${NC}"
echo "  ✓ GOST (18 protocolos)"
echo "  ✓ Shadowsocks"
echo "  ✓ Xray (VMess, VLESS, Trojan)"
echo "  ✓ Painel Web Python Flask"
echo "  ✓ Nginx com SSL"
echo "  ✓ Otimizações de rede (BBR)"
echo "  ✓ Firewall configurado"
echo ""
read -p "Deseja continuar? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Instalação cancelada."
    exit 1
fi

# Detectar IP público
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo -e "${GREEN}IP público detectado: ${PUBLIC_IP}${NC}"

# Perguntar domínio (opcional)
echo ""
echo -e "${YELLOW}Você tem um domínio para usar? (opcional)${NC}"
echo "Se não tiver, pressione ENTER para usar apenas o IP"
read -p "Domínio (ex: meuproxy.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    DOMAIN=$PUBLIC_IP
    USE_SSL=false
    echo -e "${BLUE}Usando IP: ${PUBLIC_IP}${NC}"
else
    USE_SSL=true
    echo -e "${BLUE}Usando domínio: ${DOMAIN}${NC}"
fi

# Início da instalação
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Iniciando instalação...${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""

# [1/12] Atualizar sistema
echo -e "${BLUE}[1/12] Atualizando sistema...${NC}"
apt update -qq
apt upgrade -y -qq

# [2/12] Instalar dependências
echo -e "${BLUE}[2/12] Instalando dependências...${NC}"
apt install -y -qq \
    curl wget git unzip \
    python3 python3-pip python3-venv \
    nginx certbot python3-certbot-nginx \
    sqlite3 ufw fail2ban \
    net-tools iptables

# [3/12] Ativar BBR
echo -e "${BLUE}[3/12] Ativando BBR (TCP otimizado)...${NC}"
modprobe tcp_bbr
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf

cat >> /etc/sysctl.conf << 'SYSCTL'
# GOST Performance Optimizations
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_forward=1
SYSCTL

sysctl -p > /dev/null 2>&1

# [4/12] Instalar GOST
echo -e "${BLUE}[4/12] Instalando GOST...${NC}"
GOST_VERSION="3.0.0-nightly.20241105"
wget -q https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_amd64.tar.gz
tar -xzf gost_${GOST_VERSION}_linux_amd64.tar.gz
mv gost /usr/local/bin/
chmod +x /usr/local/bin/gost
rm gost_${GOST_VERSION}_linux_amd64.tar.gz

# Criar diretórios
mkdir -p /etc/gost/certs
mkdir -p /var/log/gost

# Gerar certificados SSL auto-assinados
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/gost/certs/server.key \
    -out /etc/gost/certs/server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN}" \
    > /dev/null 2>&1

chmod 644 /etc/gost/certs/server.crt
chmod 600 /etc/gost/certs/server.key

# [5/12] Instalar Shadowsocks
echo -e "${BLUE}[5/12] Instalando Shadowsocks...${NC}"
apt install -y -qq shadowsocks-libev
mkdir -p /etc/shadowsocks-libev

# [6/12] Instalar Xray
echo -e "${BLUE}[6/12] Instalando Xray...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
mkdir -p /usr/local/etc/xray

# [7/12] Configurar SSH
echo -e "${BLUE}[7/12] Configurando SSH...${NC}"
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config
sed -i 's/#GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config
systemctl restart sshd

# [8/12] Instalar Painel Web
echo -e "${BLUE}[8/12] Instalando Painel Web...${NC}"

# Criar usuário para o painel
useradd -r -s /bin/bash -d /opt/gost-panel gostsvc || true

# Clonar repositório (assumindo que você vai subir no GitHub)
cd /opt
if [ -d "gost-panel" ]; then
    rm -rf gost-panel
fi

# IMPORTANTE: Substitua pela URL do seu repositório GitHub
GIT_REPO="https://github.com/SEU_USUARIO/gost-panel.git"

echo -e "${YELLOW}Clonando repositório...${NC}"
echo -e "${YELLOW}Se você ainda não subiu no GitHub, pressione Ctrl+C e suba primeiro!${NC}"
sleep 3

# Tentar clonar, se falhar, copiar arquivos locais
if git clone $GIT_REPO gost-panel 2>/dev/null; then
    echo -e "${GREEN}Repositório clonado com sucesso!${NC}"
else
    echo -e "${YELLOW}Não foi possível clonar. Criando estrutura básica...${NC}"
    mkdir -p gost-panel/panel
    # Aqui você copiaria os arquivos manualmente ou via scp
fi

cd /opt/gost-panel

# Criar ambiente virtual Python
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install flask qrcode pillow > /dev/null 2>&1

# Criar banco de dados
python3 -c "
import sqlite3
conn = sqlite3.connect('/opt/gost-panel/panel.db')
c = conn.cursor()
c.execute('''CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    protocol TEXT,
    listen TEXT,
    target TEXT,
    password TEXT,
    extra TEXT,
    chain_nodes TEXT
)''')
c.execute('''CREATE TABLE IF NOT EXISTS nodes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    forward TEXT
)''')
c.execute('''CREATE TABLE IF NOT EXISTS admin (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT
)''')
# Senha padrão: admin / admin123
c.execute(\"INSERT OR IGNORE INTO admin (username, password) VALUES ('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9')\")
conn.commit()
conn.close()
print('Banco de dados criado!')
"

# Ajustar permissões
chown -R gostsvc:gostsvc /opt/gost-panel
chmod 755 /opt/gost-panel
chmod 644 /opt/gost-panel/panel.db

# [9/12] Criar serviços systemd
echo -e "${BLUE}[9/12] Criando serviços systemd...${NC}"

# GOST service
cat > /etc/systemd/system/gost.service << 'EOF'
[Unit]
Description=GOST Tunnel Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -C /etc/gost/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# GOST ICMP service
cat > /etc/systemd/system/gost-icmp.service << 'EOF'
[Unit]
Description=GOST ICMP Tunnel Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -L icmp://:0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Painel service
cat > /etc/systemd/system/gost-panel.service << 'EOF'
[Unit]
Description=GOST Panel
After=network.target

[Service]
Type=simple
User=gostsvc
WorkingDirectory=/opt/gost-panel
Environment="PATH=/opt/gost-panel/venv/bin"
ExecStart=/opt/gost-panel/venv/bin/python3 /opt/gost-panel/panel/app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Configurar sudoers para gostsvc
cat > /etc/sudoers.d/gostsvc << 'EOF'
gostsvc ALL=(ALL) NOPASSWD: /bin/systemctl restart gost
gostsvc ALL=(ALL) NOPASSWD: /bin/systemctl restart shadowsocks-libev-server@config
gostsvc ALL=(ALL) NOPASSWD: /bin/systemctl restart xray
EOF

chmod 440 /etc/sudoers.d/gostsvc

# [10/12] Configurar Nginx
echo -e "${BLUE}[10/12] Configurando Nginx...${NC}"

cat > /etc/nginx/sites-available/gost-panel << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/gost-panel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

# [11/12] Configurar Firewall
echo -e "${BLUE}[11/12] Configurando firewall...${NC}"

# UFW
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Portas essenciais
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 2222/tcp comment 'SSH'

# Portas GOST
ufw allow 1080:1081/tcp comment 'SOCKS'
ufw allow 8080:8088/tcp comment 'GOST Protocols'
ufw allow 9000:9101/tcp comment 'GOST Tunnels'
ufw allow 10086:10087/tcp comment 'Xray'
ufw allow 8389/tcp comment 'Shadowsocks'
ufw allow 8443/tcp comment 'Trojan'

# UDP
ufw allow 8087:8088/udp comment 'QUIC/KCP'
ufw allow 9001/udp comment 'UDP Tunnel'
ufw allow 9003/udp comment 'RUDP'
ufw allow 9005/udp comment 'DTLS'

ufw --force enable

# [12/12] Iniciar serviços
echo -e "${BLUE}[12/12] Iniciando serviços...${NC}"

systemctl daemon-reload
systemctl enable gost gost-icmp gost-panel nginx fail2ban
systemctl start gost gost-icmp gost-panel nginx fail2ban

# Aguardar serviços iniciarem
sleep 3

# Verificar status
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Verificando instalação...${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""

# Status dos serviços
services=("gost" "gost-icmp" "gost-panel" "nginx")
all_ok=true

for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo -e "  ${GREEN}✓${NC} $service: ${GREEN}ATIVO${NC}"
    else
        echo -e "  ${RED}✗${NC} $service: ${RED}FALHOU${NC}"
        all_ok=false
    fi
done

echo ""

# Informações finais
if [ "$all_ok" = true ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║  ✅  INSTALAÇÃO CONCLUÍDA COM SUCESSO!                    ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📊 Informações de Acesso:${NC}"
    echo ""
    echo -e "  🌐 Painel Web:    ${GREEN}http://${DOMAIN}${NC}"
    echo -e "  👤 Usuário:       ${GREEN}admin${NC}"
    echo -e "  🔑 Senha:         ${GREEN}admin123${NC}"
    echo ""
    echo -e "  🔌 SSH:           ${GREEN}ssh root@${PUBLIC_IP} -p 2222${NC}"
    echo ""
    echo -e "${BLUE}📡 Protocolos Ativos:${NC}"
    echo ""
    echo "  ✓ SOCKS5 (1081), SOCKS4 (1080), HTTP (8080)"
    echo "  ✓ WSS (8082), HTTP/2 (8083), H2C (8085)"
    echo "  ✓ gRPC (8086), QUIC (8087), KCP (8088)"
    echo "  ✓ TCP (9000), UDP (9001), RTCP (9002), RUDP (9003)"
    echo "  ✓ TLS (9004), DTLS (9005), RELAY (9100), FORWARD (9101)"
    echo "  ✓ Shadowsocks (8389)"
    echo "  ✓ VMess (10086), VLESS (10087), Trojan (8443)"
    echo "  ✓ ICMP Tunnel (automático)"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
    echo "  1. Altere a senha do painel em: Configurações"
    echo "  2. Altere a senha root: passwd"
    if [ "$USE_SSL" = true ]; then
        echo "  3. Configure SSL: certbot --nginx -d ${DOMAIN}"
    fi
    echo ""
    echo -e "${BLUE}📚 Documentação:${NC}"
    echo "  - PROTOCOLS_GUIDE.md"
    echo "  - APPS_GUIDE.md"
    echo "  - MOBILE_SETUP_GUIDE.md"
    echo "  - PERFORMANCE_OPTIMIZATION.md"
    echo ""
    echo -e "${GREEN}Acesse o painel e comece a criar suas regras!${NC}"
    echo ""
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                           ║${NC}"
    echo -e "${RED}║  ⚠️  INSTALAÇÃO CONCLUÍDA COM ERROS                       ║${NC}"
    echo -e "${RED}║                                                           ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Verifique os logs:"
    echo "  journalctl -u gost -n 50"
    echo "  journalctl -u gost-panel -n 50"
    echo ""
fi

# Salvar informações
cat > /root/gost-panel-info.txt << INFO
GOST Panel - Informações de Instalação
========================================

Data: $(date)
IP Público: ${PUBLIC_IP}
Domínio: ${DOMAIN}

Painel Web: http://${DOMAIN}
Usuário: admin
Senha: admin123

SSH: ssh root@${PUBLIC_IP} -p 2222

Serviços:
- GOST: systemctl status gost
- GOST ICMP: systemctl status gost-icmp
- Painel: systemctl status gost-panel
- Nginx: systemctl status nginx

Logs:
- GOST: journalctl -u gost -f
- Painel: journalctl -u gost-panel -f

Arquivos:
- Config GOST: /etc/gost/config.json
- Banco de dados: /opt/gost-panel/panel.db
- Certificados: /etc/gost/certs/

BBR Status: $(sysctl net.ipv4.tcp_congestion_control)
INFO

echo -e "${BLUE}ℹ️  Informações salvas em: /root/gost-panel-info.txt${NC}"
echo ""
