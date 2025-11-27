# 🚀 Guia de Otimização de Performance do Servidor GOST

## 📊 Status Atual
- **23/27 túneis ativos** ✅
- Protocolos rápidos disponíveis: KCP, QUIC, RUDP

---

## 🔧 Otimizações Recomendadas

### 1️⃣ **Escolher Protocolos Mais Rápidos**

Para **máxima velocidade**, use estes protocolos na ordem:

| Protocolo | Velocidade | Latência | Uso Recomendado |
|-----------|------------|----------|-----------------|
| **KCP** (8088) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Jogos, streaming |
| **QUIC** (8087) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Navegação rápida |
| **RUDP** (9003) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Downloads grandes |
| **HTTP/2** (8083) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Streaming de vídeo |
| **SOCKS5** (1081) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Uso geral |

**Evite para velocidade:**
- ❌ Trojan (mais lento, foco em segurança)
- ❌ VMess (overhead maior)
- ❌ ICMP (muito lento, apenas para bypass)

---

### 2️⃣ **Otimizar Kernel do Linux (VPS)**

Execute na VPS para melhorar TCP/UDP:

```bash
# Criar script de otimização
cat > /root/optimize_network.sh << 'EOF'
#!/bin/bash

echo "🚀 Otimizando rede do servidor..."

# Aumentar buffers TCP/UDP
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.wmem_max=134217728
sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"
sysctl -w net.ipv4.udp_rmem_min=8192
sysctl -w net.ipv4.udp_wmem_min=8192

# Melhorar congestionamento TCP
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.core.default_qdisc=fq

# Aumentar limite de conexões
sysctl -w net.core.somaxconn=4096
sysctl -w net.ipv4.tcp_max_syn_backlog=8192

# Reduzir TIME_WAIT
sysctl -w net.ipv4.tcp_fin_timeout=15
sysctl -w net.ipv4.tcp_tw_reuse=1

# Salvar permanentemente
cat >> /etc/sysctl.conf << 'SYSCTL'
# GOST Performance Optimizations
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
SYSCTL

echo "✅ Otimizações aplicadas!"
sysctl -p
EOF

chmod +x /root/optimize_network.sh
/root/optimize_network.sh
```

---

### 3️⃣ **Configurar BBR (TCP Congestion Control)**

BBR é **muito mais rápido** que o padrão:

```bash
# Verificar se BBR está disponível
lsmod | grep tcp_bbr

# Se não estiver, carregar
modprobe tcp_bbr
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf

# Ativar BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# Verificar
sysctl net.ipv4.tcp_congestion_control
# Deve mostrar: net.ipv4.tcp_congestion_control = bbr
```

---

### 4️⃣ **Usar DNS Rápido no Cliente**

Configure DNS rápido no seu computador/celular:

**Opções (do mais rápido ao mais lento):**
1. **Cloudflare**: `1.1.1.1` e `1.0.0.1`
2. **Google**: `8.8.8.8` e `8.8.4.4`
3. **Quad9**: `9.9.9.9`

**No Windows:**
```powershell
# PowerShell como Admin
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("1.1.1.1","1.0.0.1")
```

**No Android:**
1. Configurações → Rede → Wi-Fi
2. Toque na rede conectada
3. Avançado → DNS 1: `1.1.1.1`, DNS 2: `1.0.0.1`

---

### 5️⃣ **Otimizar Configuração do GOST**

Edite `/etc/gost/config.json` e adicione opções de performance:

```json
{
  "services": [
    {
      "name": "KCP-FAST",
      "addr": ":8088",
      "handler": {"type": "socks5"},
      "listener": {
        "type": "kcp",
        "kcp": {
          "key": "your-secret-key",
          "crypt": "aes",
          "mode": "fast3",
          "mtu": 1350,
          "sndwnd": 1024,
          "rcvwnd": 1024,
          "datashard": 10,
          "parityshard": 3
        }
      }
    }
  ]
}
```

**Modos KCP (do mais rápido ao mais confiável):**
- `fast3` - Máxima velocidade (use este!)
- `fast2` - Velocidade alta
- `fast` - Velocidade média
- `normal` - Padrão

---

### 6️⃣ **Testar Velocidade**

**No cliente (Windows):**
```powershell
# Teste sem proxy
Invoke-WebRequest -Uri "https://speed.cloudflare.com/__down?bytes=100000000" -OutFile "nul"

# Teste com proxy SOCKS5
$proxy = [System.Net.WebProxy]::new('socks5://138.197.212.221:1081')
Invoke-WebRequest -Uri "https://speed.cloudflare.com/__down?bytes=100000000" -Proxy $proxy -OutFile "nul"
```

**Comparar protocolos:**
1. KCP (8088) - Mais rápido
2. QUIC (8087) - Rápido
3. SOCKS5 (1081) - Baseline
4. VMess (10086) - Mais lento

---

### 7️⃣ **Monitorar Performance**

```bash
# Ver uso de banda em tempo real
iftop -i eth0

# Ver conexões ativas
ss -s

# Ver uso de CPU/RAM do GOST
top -p $(pgrep gost)
```

---

## 🎯 Recomendações por Caso de Uso

### 📱 **Navegação Web Rápida**
```
Protocolo: QUIC (8087) ou HTTP/2 (8083)
App: v2rayNG, Clash
```

### 🎮 **Jogos (Baixa Latência)**
```
Protocolo: KCP (8088) modo fast3
App: v2rayNG com KCP
```

### 📺 **Streaming de Vídeo**
```
Protocolo: HTTP/2 (8083) ou RUDP (9003)
App: Clash, v2rayNG
```

### 📥 **Downloads Grandes**
```
Protocolo: RUDP (9003) ou TCP (9000)
App: Qualquer
```

---

## ⚡ Checklist de Otimização

Execute na VPS:

```bash
# 1. Ativar BBR
sudo modprobe tcp_bbr
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 2. Otimizar buffers
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728

# 3. Reiniciar GOST para aplicar
sudo systemctl restart gost

# 4. Testar
curl -x socks5://localhost:1081 https://speed.cloudflare.com/cdn-cgi/trace
```

---

## 📊 Resultados Esperados

Após otimizações:
- ✅ **Latência**: Redução de 20-40%
- ✅ **Velocidade de download**: Aumento de 30-50%
- ✅ **Velocidade de upload**: Aumento de 20-30%
- ✅ **Conexões simultâneas**: Até 4x mais

---

## 🆘 Troubleshooting

### Velocidade ainda lenta?

1. **Teste a VPS diretamente:**
   ```bash
   curl -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000
   ```

2. **Verifique se BBR está ativo:**
   ```bash
   sysctl net.ipv4.tcp_congestion_control
   ```

3. **Mude para protocolo mais rápido:**
   - Troque de VMess → KCP
   - Troque de Trojan → QUIC

4. **Verifique limites da VPS:**
   - DigitalOcean Droplet básico: ~1 Gbps
   - Pode estar limitado pelo plano

---

**Última atualização:** 26 de Novembro de 2025  
**Status:** 23/27 túneis ativos ✅
