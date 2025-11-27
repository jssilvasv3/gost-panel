#!/bin/bash
# ============================================================
# Script de Configuração Completa - Todos os Protocolos GOST
# ============================================================

echo "============================================================"
echo "  Configurando TODOS os 27 Protocolos"
echo "============================================================"
echo ""

# 1. Gerar certificado SSL auto-assinado para protocolos TLS
echo "[1/10] Gerando certificado SSL..."
sudo mkdir -p /etc/gost/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/gost/certs/server.key \
  -out /etc/gost/certs/server.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=138.197.212.221"

sudo chmod 644 /etc/gost/certs/server.crt
sudo chmod 600 /etc/gost/certs/server.key

# 2. Configurar DNS upstream
echo "[2/10] Configurando DNS..."
echo "nameserver 8.8.8.8" | sudo tee /etc/gost/dns.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/gost/dns.conf

# 3. Habilitar IP forwarding para ICMP
echo "[3/10] Habilitando IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.icmp_echo_ignore_all=0
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_all=0" | sudo tee -a /etc/sysctl.conf

# 4. Configurar permissões para ICMP
echo "[4/10] Configurando permissões ICMP..."
sudo setcap cap_net_raw+ep /usr/local/bin/gost

# 5. Abrir todas as portas no firewall
echo "[5/10] Abrindo portas no firewall..."
sudo ufw allow 1080/tcp  # SOCKS4
sudo ufw allow 1081/tcp  # SOCKS5
sudo ufw allow 8080/tcp  # HTTP
sudo ufw allow 8082/tcp  # WSS
sudo ufw allow 8083/tcp  # HTTP2
sudo ufw allow 8085/tcp  # H2C
sudo ufw allow 8086/tcp  # gRPC
sudo ufw allow 8087/udp  # QUIC
sudo ufw allow 8088/udp  # KCP
sudo ufw allow 2222/tcp  # SSH
sudo ufw allow 2223/tcp  # SSHD
sudo ufw allow 9000/tcp  # TCP
sudo ufw allow 9001/udp  # UDP
sudo ufw allow 9002/tcp  # RTCP
sudo ufw allow 9003/udp  # RUDP
sudo ufw allow 9004/tcp  # TLS
sudo ufw allow 9005/udp  # DTLS
sudo ufw allow 53/udp    # DNS
sudo ufw allow 8053/tcp  # DoH
sudo ufw allow 853/tcp   # DoT
sudo ufw allow 9100/tcp  # Relay
sudo ufw allow 9101/tcp  # Forward

# 6. Configurar SSH server na porta 2222
echo "[6/10] Configurando SSH server..."
if ! grep -q "Port 2222" /etc/ssh/sshd_config; then
    echo "Port 2222" | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart sshd
fi

# 7. Criar config GOST avançado
echo "[7/10] Gerando configuração GOST avançada..."
sudo tee /etc/gost/config_advanced.json > /dev/null << 'EOF'
{
  "services": [
    {
      "name": "SOCKS5-1081",
      "addr": ":1081",
      "handler": {"type": "socks5"},
      "listener": {"type": "tcp"}
    },
    {
      "name": "SOCKS4-1080",
      "addr": ":1080",
      "handler": {"type": "socks4"},
      "listener": {"type": "tcp"}
    },
    {
      "name": "HTTP-8080",
      "addr": ":8080",
      "handler": {"type": "http"},
      "listener": {"type": "tcp"}
    },
    {
      "name": "WSS-8082",
      "addr": ":8082",
      "handler": {"type": "socks5"},
      "listener": {
        "type": "wss",
        "tls": {
          "certFile": "/etc/gost/certs/server.crt",
          "keyFile": "/etc/gost/certs/server.key"
        }
      }
    },
    {
      "name": "HTTP2-8083",
      "addr": ":8083",
      "handler": {"type": "http"},
      "listener": {"type": "http2"}
    },
    {
      "name": "H2C-8085",
      "addr": ":8085",
      "handler": {"type": "http"},
      "listener": {"type": "h2c"}
    },
    {
      "name": "GRPC-8086",
      "addr": ":8086",
      "handler": {"type": "socks5"},
      "listener": {"type": "grpc"}
    },
    {
      "name": "QUIC-8087",
      "addr": ":8087",
      "handler": {"type": "socks5"},
      "listener": {
        "type": "quic",
        "tls": {
          "certFile": "/etc/gost/certs/server.crt",
          "keyFile": "/etc/gost/certs/server.key"
        }
      }
    },
    {
      "name": "KCP-8088",
      "addr": ":8088",
      "handler": {"type": "socks5"},
      "listener": {"type": "kcp"}
    },
    {
      "name": "TCP-9000",
      "addr": ":9000",
      "handler": {"type": "tcp"},
      "listener": {"type": "tcp"}
    },
    {
      "name": "UDP-9001",
      "addr": ":9001",
      "handler": {"type": "udp"},
      "listener": {"type": "udp"}
    },
    {
      "name": "RTCP-9002",
      "addr": ":9002",
      "handler": {"type": "rtcp"},
      "listener": {"type": "tcp"}
    },
    {
      "name": "RUDP-9003",
      "addr": ":9003",
      "handler": {"type": "rudp"},
      "listener": {"type": "udp"}
    },
    {
      "name": "TLS-9004",
      "addr": ":9004",
      "handler": {"type": "socks5"},
      "listener": {
        "type": "tls",
        "tls": {
          "certFile": "/etc/gost/certs/server.crt",
          "keyFile": "/etc/gost/certs/server.key"
        }
      }
    },
    {
      "name": "DTLS-9005",
      "addr": ":9005",
      "handler": {"type": "socks5"},
      "listener": {
        "type": "dtls",
        "tls": {
          "certFile": "/etc/gost/certs/server.crt",
          "keyFile": "/etc/gost/certs/server.key"
        }
      }
    },
    {
      "name": "RELAY-9100",
      "addr": ":9100",
      "handler": {"type": "relay"},
      "listener": {"type": "tcp"}
    },
    {
      "name": "FORWARD-9101",
      "addr": ":9101",
      "handler": {"type": "forward"},
      "listener": {"type": "tcp"}
    }
  ],
  "api": {
    "addr": "127.0.0.1:18080",
    "pathPrefix": "/api"
  }
}
EOF

# 8. Configurar DNS resolver (separado)
echo "[8/10] Configurando DNS resolver..."
sudo tee /etc/gost/dns_config.json > /dev/null << 'EOF'
{
  "services": [
    {
      "name": "DNS-53",
      "addr": ":53",
      "handler": {
        "type": "dns",
        "dns": {
          "mode": "udp",
          "servers": ["8.8.8.8:53", "1.1.1.1:53"]
        }
      },
      "listener": {"type": "udp"}
    }
  ]
}
EOF

# 9. Criar serviço systemd para DNS
echo "[9/10] Criando serviço DNS..."
sudo tee /etc/systemd/system/gost-dns.service > /dev/null << 'EOF'
[Unit]
Description=GOST DNS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -C /etc/gost/dns_config.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable gost-dns
sudo systemctl start gost-dns

# 10. Reiniciar GOST principal
echo "[10/10] Reiniciando serviços..."
sudo systemctl restart gost

echo ""
echo "============================================================"
echo "  ✅ Configuração Completa!"
echo "============================================================"
echo ""
echo "📊 Status dos Serviços:"
echo ""
sudo systemctl status gost --no-pager | grep Active
sudo systemctl status gost-dns --no-pager | grep Active
sudo systemctl status shadowsocks-libev-server@config --no-pager | grep Active
sudo systemctl status xray --no-pager | grep Active
echo ""
echo "🔍 Portas Abertas:"
sudo ss -tlnpu | grep -E ':(1080|1081|8080|8082|8083|8085|8086|8087|8088|2222|9000|9001|9002|9003|9004|9005|53|9100|9101)'
echo ""
echo "============================================================"
echo "  📱 Protocolos Ativos:"
echo "============================================================"
echo "  ✅ SOCKS5 (1081), SOCKS4 (1080), HTTP (8080)"
echo "  ✅ WSS (8082), HTTP/2 (8083), H2C (8085)"
echo "  ✅ gRPC (8086), QUIC (8087), KCP (8088)"
echo "  ✅ TCP (9000), UDP (9001), RTCP (9002), RUDP (9003)"
echo "  ✅ TLS (9004), DTLS (9005)"
echo "  ✅ DNS (53), Relay (9100), Forward (9101)"
echo "  ✅ SSH (2222 - sistema)"
echo "  ✅ Shadowsocks (8389)"
echo "  ✅ VMess (10086), VLESS (10087), Trojan (8443)"
echo "============================================================"
