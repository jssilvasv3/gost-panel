# 📚 Guia Completo de Protocolos GOST

Este guia documenta TODOS os protocolos suportados pelo painel GOST e como usá-los.

---

## 🔒 Proxies Básicos

### SOCKS5 (Porta 1081)
**Uso:** Proxy genérico mais comum
**Apps:** v2rayNG, Shadowrocket, Postern
**Configuração:**
```
Servidor: 138.197.212.221
Porta: 1081
```

### SOCKS4 (Porta 1080)
**Uso:** Versão antiga do SOCKS
**Apps:** Mesmos do SOCKS5
**Configuração:** Similar ao SOCKS5

### HTTP Proxy (Porta 8080)
**Uso:** Proxy HTTP padrão
**Apps:** Configurações do sistema, navegadores
**Configuração:**
```
Servidor: 138.197.212.221
Porta: 8080
```

### HTTPS Proxy (Porta 8443)
**Uso:** Proxy HTTP com TLS
**Apps:** Mesmos do HTTP

---

## 🛡️ Protocolos Criptografados (Xray)

### Shadowsocks (Porta 8389)
**Uso:** Proxy criptografado popular
**Apps:** Shadowsocks, v2rayNG
**Configuração:** Via QR Code ou manual
**Método:** aes-256-gcm

### VMess (Porta 10086)
**Uso:** Protocolo V2Ray
**Apps:** v2rayNG, Shadowrocket
**Configuração:** Via QR Code
**UUID:** Auto-gerado

### VLESS (Porta 10087)
**Uso:** VMess sem criptografia extra
**Apps:** v2rayNG, Shadowrocket
**Configuração:** Via QR Code
**UUID:** Auto-gerado

### Trojan (Porta 8443)
**Uso:** Proxy que imita HTTPS
**Apps:** v2rayNG, Shadowrocket, Clash
**Configuração:** Via QR Code
**Senha:** Auto-gerada

---

## 🚀 Protocolos Avançados (GOST)

### WebSocket (WS) - Porta 8081
**Uso:** Túnel sobre WebSocket
**Vantagens:** Passa por firewalls HTTP
**Exemplo:**
```
Cliente: ws://138.197.212.221:8081
```

### WebSocket Secure (WSS) - Porta 8082
**Uso:** WebSocket com TLS
**Vantagens:** Criptografado, passa por firewalls
**Exemplo:**
```
Cliente: wss://138.197.212.221:8082
```

### HTTP/2 (Porta 8083)
**Uso:** Túnel sobre HTTP/2
**Vantagens:** Multiplexing, compressão
**Exemplo:**
```
Cliente: http2://138.197.212.221:8083
```

### H2 (Porta 8084)
**Uso:** HTTP/2 com TLS
**Vantagens:** Seguro e rápido

### H2C (Porta 8085)
**Uso:** HTTP/2 sem TLS
**Vantagens:** Mais rápido que HTTP/1.1

### gRPC (Porta 8086)
**Uso:** Túnel sobre gRPC
**Vantagens:** Eficiente, passa por CDNs
**Exemplo:**
```
Cliente: grpc://138.197.212.221:8086
```

### QUIC (Porta 8087)
**Uso:** UDP-based transport
**Vantagens:** Baixa latência, resistente a perda de pacotes
**Exemplo:**
```
Cliente: quic://138.197.212.221:8087
```

### KCP (Porta 8088)
**Uso:** UDP-based ARQ protocol
**Vantagens:** Baixa latência, bom para jogos
**Exemplo:**
```
Cliente: kcp://138.197.212.221:8088
```

### SSH Tunnel (Porta 2222)
**Uso:** Túnel SSH
**Vantagens:** Seguro, amplamente suportado
**Exemplo:**
```bash
ssh -D 1080 -p 2222 user@138.197.212.221
```

### SSH Server (SSHD) - Porta 2223
**Uso:** Servidor SSH completo
**Vantagens:** Acesso remoto + túnel

---

## 🔧 Túneis Especiais

### TCP Tunnel (Porta 9000)
**Uso:** Encaminhamento TCP puro
**Exemplo:** Encaminhar porta local para remota
```
Local :3306 → Remote mysql:3306
```

### UDP Tunnel (Porta 9001)
**Uso:** Encaminhamento UDP
**Exemplo:** DNS, VoIP, jogos

### RTCP (Porta 9002)
**Uso:** TCP confiável
**Vantagens:** Retransmissão automática

### RUDP (Porta 9003)
**Uso:** UDP confiável
**Vantagens:** Baixa latência + confiabilidade

### TLS Tunnel (Porta 9004)
**Uso:** Túnel TLS puro
**Vantagens:** Criptografia forte

### DTLS (Porta 9005)
**Uso:** TLS sobre UDP
**Vantagens:** Seguro + baixa latência

### ICMP Tunnel (Porta 9006)
**Uso:** Túnel sobre ICMP (ping)
**Vantagens:** Passa por firewalls restritivos
**Nota:** Requer root/admin

---

## 🌐 DNS & Redes

### DNS Proxy (Porta 53)
**Uso:** Proxy DNS
**Exemplo:**
```
nslookup google.com 138.197.212.221
```

### DNS over HTTPS (DoH) - Porta 8053
**Uso:** DNS criptografado via HTTPS
**Vantagens:** Privacidade, anti-censura
**Exemplo:**
```
https://138.197.212.221:8053/dns-query
```

### DNS over TLS (DoT) - Porta 853
**Uso:** DNS criptografado via TLS
**Vantagens:** Privacidade

### Relay (Porta 9100)
**Uso:** Relay de conexões
**Vantagens:** Encadeamento de proxies

### Forward (Porta 9101)
**Uso:** Encaminhamento simples
**Vantagens:** Port forwarding

---

## 🔗 Recursos Avançados

### Chain Multi-Hop
**Uso:** Encadear múltiplos proxies
**Como usar:**
1. Crie Nodes no painel
2. Configure chain_nodes na regra
3. Tráfego passa por todos os nodes

**Exemplo:**
```
Cliente → Node1 → Node2 → Destino
```

### Load Balancing
**Uso:** Distribuir tráfego entre múltiplos destinos
**Estratégias:**
- `round`: Round-robin
- `random`: Aleatório
- `hash`: Hash do IP

**Como usar:**
- Target: `tcp://server1:80,tcp://server2:80`
- Extra: `strategy=round`

### Rate Limiting
**Uso:** Limitar velocidade
**Como usar:**
- Extra: `rl=1024` (KB/s)

---

## 📱 Compatibilidade Mobile

| Protocolo | Android | iOS | QR Code |
|-----------|---------|-----|---------|
| SOCKS5 | ✅ v2rayNG | ✅ Shadowrocket | ✅ |
| Shadowsocks | ✅ Shadowsocks | ✅ Shadowsocks | ✅ |
| VMess | ✅ v2rayNG | ✅ Shadowrocket | ✅ |
| VLESS | ✅ v2rayNG | ✅ Shadowrocket | ✅ |
| Trojan | ✅ v2rayNG | ✅ Shadowrocket | ✅ |
| HTTP | ✅ Sistema | ✅ Sistema | ❌ |
| WebSocket | ✅ v2rayNG | ✅ Shadowrocket | ⚠️ |
| gRPC | ✅ v2rayNG | ✅ Shadowrocket | ⚠️ |

---

## 🎯 Casos de Uso

### Para Navegação Web
**Recomendado:** SOCKS5, HTTP, Shadowsocks
**Porta:** 1081, 8080, 8389

### Para Jogos
**Recomendado:** KCP, QUIC, RUDP
**Porta:** 8088, 8087, 9003
**Vantagem:** Baixa latência

### Para Streaming
**Recomendado:** HTTP/2, gRPC
**Porta:** 8083, 8086
**Vantagem:** Alta velocidade

### Para Bypass de Firewall
**Recomendado:** WSS, DoH, ICMP
**Porta:** 8082, 8053, 9006
**Vantagem:** Difícil de bloquear

### Para Máxima Segurança
**Recomendado:** Trojan, TLS, SSH
**Porta:** 8443, 9004, 2222
**Vantagem:** Criptografia forte

---

## 🔍 Troubleshooting

### Protocolo não conecta
1. Verifique se a porta está aberta no firewall
2. Veja logs: `sudo journalctl -u gost -n 50`
3. Teste localmente: `curl -x protocol://localhost:port https://api.ipify.org`

### Lento
1. Use KCP ou QUIC para baixa latência
2. Ative compressão (HTTP/2, gRPC)
3. Use Load Balancing

### Bloqueado
1. Mude para WSS ou DoH
2. Use ICMP tunnel
3. Configure Chain Multi-Hop

---

## 📊 Performance Comparison

| Protocolo | Velocidade | Latência | Segurança | Bypass |
|-----------|------------|----------|-----------|--------|
| SOCKS5 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Shadowsocks | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| VMess | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Trojan | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| WebSocket | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| gRPC | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| QUIC | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| KCP | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

---

**Pronto! Agora você tem acesso a TODOS os protocolos do GOST!** 🎉
