# 📱 Guia Completo: Configurar Todos os Protocolos no Celular

Este guia mostra como configurar TODOS os protocolos do painel GOST no celular (Android/iOS).

---

## 📋 Protocolos Disponíveis e Apps Necessários

| Protocolo | Android | iOS | Facilidade |
|-----------|---------|-----|------------|
| **SOCKS5** | v2rayNG, Postern | Shadowrocket | ⭐⭐⭐ |
| **Shadowsocks** | Shadowsocks | Shadowsocks, Potatso | ⭐⭐⭐⭐⭐ |
| **VMess** | v2rayNG | Shadowrocket, Quantumult | ⭐⭐⭐⭐ |
| **VLESS** | v2rayNG | Shadowrocket | ⭐⭐⭐⭐ |
| **Trojan** | v2rayNG, Clash | Shadowrocket | ⭐⭐⭐ |
| **HTTP/HTTPS** | Qualquer navegador | Qualquer navegador | ⭐⭐ |

---

## 🚀 Configuração Rápida - Passo a Passo

### 1️⃣ SOCKS5 (Porta 1081)

**✅ Já está configurado!**

**Android - v2rayNG:**
1. Baixe: [v2rayNG](https://github.com/2dust/v2rayNG/releases)
2. Toque em **+** → **Tipo: SOCKS**
3. Configure:
   - **Endereço:** `138.197.212.221`
   - **Porta:** `1081`
   - **Versão:** SOCKS5
4. Salve e conecte

**iOS - Shadowrocket:**
1. Compre: [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118) (~$3)
2. **+** → **Type: SOCKS5**
3. Configure:
   - **Host:** `138.197.212.221`
   - **Port:** `1081`

---

### 2️⃣ Shadowsocks (Recomendado para Mobile)

**Criar no Painel:**

1. Acesse: `http://138.197.212.221:5000`
2. **➕ Criar Regra**
3. Preencha:
   ```
   Nome: Shadowsocks Mobile
   Protocolo: ss
   Listen: :8388
   Target: tcp://8.8.8.8:53
   Senha: MinhaS3nh@Forte
   Extra: method=aes-256-gcm
   ```
4. **Aplicar Configuração**

**Android - Shadowsocks:**
1. Baixe: [Shadowsocks](https://play.google.com/store/apps/details?id=com.github.shadowsocks)
2. **+** → **Adicionar Perfil Manualmente**
3. Configure:
   - **Servidor:** `138.197.212.221`
   - **Porta:** `8388`
   - **Senha:** `MinhaS3nh@Forte`
   - **Método:** `aes-256-gcm`
4. Conecte

**iOS - Shadowsocks:**
1. Baixe: [Shadowsocks](https://apps.apple.com/app/shadowsocks/id665729974)
2. Configure igual ao Android

**📱 Ou use QR Code:**
- No painel, clique em **📱 QR Code** na regra
- Escaneie com o app

---

### 3️⃣ VMess (V2Ray)

**Criar no Painel:**

1. **➕ Criar Regra**
2. Preencha:
   ```
   Nome: VMess Mobile
   Protocolo: vmess
   Listen: :10086
   Target: tcp://8.8.8.8:53
   Senha: (deixe vazio - será gerado UUID)
   Extra: uuid=sua-uuid-aqui,alterId=0
   ```
3. **Aplicar Configuração**

**Gerar UUID:**
```bash
# Na VPS
uuidgen
# Exemplo: 12345678-1234-1234-1234-123456789012
```

**Android - v2rayNG:**
1. **+** → **Tipo: VMess**
2. Configure:
   - **Endereço:** `138.197.212.221`
   - **Porta:** `10086`
   - **UUID:** `sua-uuid-aqui`
   - **AlterID:** `0`
   - **Segurança:** `auto`
   - **Rede:** `tcp`

**iOS - Shadowrocket:**
1. **+** → **Type: VMess**
2. Configure igual

---

### 4️⃣ VLESS (V2Ray Next-Gen)

**Criar no Painel:**

1. **➕ Criar Regra**
2. Preencha:
   ```
   Nome: VLESS Mobile
   Protocolo: vless
   Listen: :10087
   Target: tcp://8.8.8.8:53
   Extra: uuid=sua-uuid-aqui,flow=xtls-rprx-direct
   ```
3. **Aplicar Configuração**

**Android - v2rayNG:**
1. **+** → **Tipo: VLESS**
2. Configure:
   - **Endereço:** `138.197.212.221`
   - **Porta:** `10087`
   - **UUID:** `sua-uuid-aqui`
   - **Encryption:** `none`

---

### 5️⃣ Trojan

**Criar no Painel:**

1. **➕ Criar Regra**
2. Preencha:
   ```
   Nome: Trojan Mobile
   Protocolo: trojan
   Listen: :443
   Target: tcp://8.8.8.8:53
   Senha: MinhaS3nh@Trojan
   Extra: sni=seu.dominio.com
   ```
3. **Aplicar Configuração**

**Android - v2rayNG:**
1. **+** → **Tipo: Trojan**
2. Configure:
   - **Endereço:** `138.197.212.221`
   - **Porta:** `443`
   - **Senha:** `MinhaS3nh@Trojan`

---

### 6️⃣ HTTP/HTTPS Proxy

**Criar no Painel:**

1. **➕ Criar Regra**
2. Preencha:
   ```
   Nome: HTTP Proxy
   Protocolo: http
   Listen: :8080
   Target: tcp://8.8.8.8:53
   ```
3. **Aplicar Configuração**

**Android/iOS - Configurações do Sistema:**
1. **WiFi** → Sua rede → **Configurar Proxy**
2. **Manual:**
   - **Servidor:** `138.197.212.221`
   - **Porta:** `8080`

---

## 📱 Apps Recomendados

### 🤖 Android (Melhor → Pior)

1. **v2rayNG** (Grátis) - Suporta tudo
   - [Download](https://github.com/2dust/v2rayNG/releases)
   - ✅ SOCKS5, Shadowsocks, VMess, VLESS, Trojan

2. **Shadowsocks** (Grátis) - Mais simples
   - [Play Store](https://play.google.com/store/apps/details?id=com.github.shadowsocks)
   - ✅ Shadowsocks apenas

3. **Clash for Android** (Grátis) - Avançado
   - [GitHub](https://github.com/Kr328/ClashForAndroid)
   - ✅ Todos os protocolos + regras

### 🍎 iOS

1. **Shadowrocket** ($2.99) - Melhor custo-benefício
   - [App Store](https://apps.apple.com/app/shadowrocket/id932747118)
   - ✅ Todos os protocolos

2. **Quantumult X** ($7.99) - Mais avançado
   - [App Store](https://apps.apple.com/app/quantumult-x/id1443988620)
   - ✅ Todos os protocolos + regras complexas

3. **Potatso Lite** (Grátis) - Básico
   - [App Store](https://apps.apple.com/app/potatso-lite/id1239860606)
   - ✅ Shadowsocks apenas

---

## 🔥 Configuração Completa - Todos os Protocolos

**Execute no painel ou via API:**

```bash
# 1. SOCKS5 (já configurado)
# Porta: 1081

# 2. Shadowsocks
Nome: SS-Mobile
Protocolo: ss
Listen: :8388
Senha: Senha123!
Extra: method=aes-256-gcm

# 3. VMess
Nome: VMess-Mobile
Protocolo: vmess
Listen: :10086
Extra: uuid=$(uuidgen),alterId=0

# 4. VLESS
Nome: VLESS-Mobile
Protocolo: vless
Listen: :10087
Extra: uuid=$(uuidgen)

# 5. HTTP Proxy
Nome: HTTP-Proxy
Protocolo: http
Listen: :8080

# 6. HTTPS Proxy
Nome: HTTPS-Proxy
Protocolo: https
Listen: :8443
```

**Abrir portas no firewall:**

```bash
# Na VPS
sudo iptables -I INPUT -p tcp --dport 8388 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 10086 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 10087 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 8443 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT

# Salvar
sudo iptables-save > /etc/iptables/rules.v4
```

---

## 🎯 Recomendação Final

**Para uso diário no celular:**

1. **🥇 Shadowsocks** - Mais estável e rápido
   - Porta: 8388
   - App: Shadowsocks (Android/iOS)

2. **🥈 VMess** - Mais recursos
   - Porta: 10086
   - App: v2rayNG (Android) / Shadowrocket (iOS)

3. **🥉 SOCKS5** - Mais simples
   - Porta: 1081
   - App: v2rayNG (Android) / Shadowrocket (iOS)

---

## 📊 Teste de Velocidade

Após configurar, teste em: https://fast.com

**Velocidade esperada:**
- SOCKS5: ⭐⭐⭐⭐⭐ (mais rápido)
- Shadowsocks: ⭐⭐⭐⭐⭐ (muito rápido)
- VMess: ⭐⭐⭐⭐ (rápido)
- VLESS: ⭐⭐⭐⭐ (rápido)
- HTTP: ⭐⭐⭐ (médio)

---

## 🆘 Troubleshooting

**Não conecta:**
1. Verifique firewall: `sudo iptables -L -n`
2. Verifique se GOST está rodando: `sudo systemctl status gost`
3. Verifique portas abertas: `sudo ss -tlnp | grep gost`
4. Veja logs: `sudo journalctl -u gost -f`

**Conecta mas não navega:**
1. Verifique o campo `Target` na regra
2. Teste com: `tcp://8.8.8.8:53` ou `tcp://1.1.1.1:53`

**Lento:**
1. Use Shadowsocks ao invés de SOCKS5
2. Ative compressão no app
3. Escolha servidor mais próximo

---

**Pronto! Agora você tem TODOS os protocolos disponíveis para celular!** 📱🚀
