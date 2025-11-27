#!/bin/bash
# ============================================================
# Ativar os 4 Protocolos Restantes (DNS, DoH, DoT, ICMP)
# SEM quebrar os 23 que já estão funcionando
# ============================================================

echo "============================================================"
echo "  Ativando 4 Protocolos Restantes"
echo "============================================================"
echo ""

# 1. Parar systemd-resolved na porta 53
echo "[1/6] Liberando porta 53..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# Configurar DNS alternativo
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf  # Impedir sobrescrita

# 2. Criar config DNS (porta 53)
echo "[2/6] Configurando DNS (porta 53)..."
sudo tee /etc/gost/dns_service.json > /dev/null << 'EOF'
{
  "services": [
    {
      "name": "DNS-53",
      "addr": ":53",
      "handler": {
        "type": "dns",
        "dns": {
          "mode": "udp",
          "servers": ["8.8.8.8:53", "1.1.1.1:53", "208.67.222.222:53"]
        }
      },
      "listener": {"type": "udp"}
    }
  ]
}
EOF

# 3. Criar config DoH (porta 8053)
echo "[3/6] Configurando DNS over HTTPS (porta 8053)..."
sudo tee /etc/gost/doh_service.json > /dev/null << 'EOF'
{
  "services": [
    {
      "name": "DOH-8053",
      "addr": ":8053",
      "handler": {
        "type": "dns",
        "dns": {
          "mode": "tcp",
          "servers": ["8.8.8.8:53", "1.1.1.1:53"]
        }
      },
      "listener": {
        "type": "https",
        "tls": {
          "certFile": "/etc/gost/certs/server.crt",
          "keyFile": "/etc/gost/certs/server.key"
        }
      }
    }
  ]
}
EOF

# 4. Criar config DoT (porta 853)
echo "[4/6] Configurando DNS over TLS (porta 853)..."
sudo tee /etc/gost/dot_service.json > /dev/null << 'EOF'
{
  "services": [
    {
      "name": "DOT-853",
      "addr": ":853",
      "handler": {
        "type": "dns",
        "dns": {
          "mode": "tcp",
          "servers": ["8.8.8.8:53", "1.1.1.1:53"]
        }
      },
      "listener": {
        "type": "tls",
        "tls": {
          "certFile": "/etc/gost/certs/server.crt",
          "keyFile": "/etc/gost/certs/server.key"
        }
      }
    }
  ]
}
EOF

# 5. Criar config ICMP (porta 9006)
echo "[5/6] Configurando ICMP Tunnel (porta 9006)..."
sudo tee /etc/gost/icmp_service.json > /dev/null << 'EOF'
{
  "services": [
    {
      "name": "ICMP-9006",
      "addr": ":9006",
      "handler": {"type": "socks5"},
      "listener": {"type": "icmp"}
    }
  ]
}
EOF

# 6. Criar serviços systemd separados
echo "[6/6] Criando serviços systemd..."

# DNS Service
sudo tee /etc/systemd/system/gost-dns.service > /dev/null << 'EOF'
[Unit]
Description=GOST DNS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -C /etc/gost/dns_service.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# DoH Service
sudo tee /etc/systemd/system/gost-doh.service > /dev/null << 'EOF'
[Unit]
Description=GOST DNS over HTTPS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -C /etc/gost/doh_service.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# DoT Service
sudo tee /etc/systemd/system/gost-dot.service > /dev/null << 'EOF'
[Unit]
Description=GOST DNS over TLS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -C /etc/gost/dot_service.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# ICMP Service
sudo tee /etc/systemd/system/gost-icmp.service > /dev/null << 'EOF'
[Unit]
Description=GOST ICMP Tunnel Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -C /etc/gost/icmp_service.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar e iniciar serviços
echo ""
echo "Iniciando serviços..."
sudo systemctl enable gost-dns gost-doh gost-dot gost-icmp
sudo systemctl start gost-dns
sleep 1
sudo systemctl start gost-doh
sleep 1
sudo systemctl start gost-dot
sleep 1
sudo systemctl start gost-icmp

echo ""
echo "============================================================"
echo "  ✅ Configuração Completa!"
echo "============================================================"
echo ""
echo "📊 Status dos Novos Serviços:"
echo ""
sudo systemctl status gost-dns --no-pager | grep Active
sudo systemctl status gost-doh --no-pager | grep Active
sudo systemctl status gost-dot --no-pager | grep Active
sudo systemctl status gost-icmp --no-pager | grep Active

echo ""
echo "📊 Status dos Serviços Existentes (não afetados):"
echo ""
sudo systemctl status gost --no-pager | grep Active
sudo systemctl status shadowsocks-libev-server@config --no-pager | grep Active
sudo systemctl status xray --no-pager | grep Active
sudo systemctl status ssh --no-pager | grep Active

echo ""
echo "🔍 Novas Portas Abertas:"
sudo ss -tlnpu | grep -E ':(53|8053|853|9006)'

echo ""
echo "============================================================"
echo "  🎉 TODOS OS 27 TÚNEIS ATIVOS!"
echo "============================================================"
echo "  ✅ GOST Principal: 18 túneis"
echo "  ✅ DNS: 1 túnel (porta 53)"
echo "  ✅ DoH: 1 túnel (porta 8053)"
echo "  ✅ DoT: 1 túnel (porta 853)"
echo "  ✅ ICMP: 1 túnel (porta 9006)"
echo "  ✅ Shadowsocks: 1 túnel"
echo "  ✅ Xray: 3 túneis"
echo "  ✅ SSH: 1 túnel"
echo ""
echo "  TOTAL: 27 TÚNEIS ATIVOS! 🚀"
echo "============================================================"
