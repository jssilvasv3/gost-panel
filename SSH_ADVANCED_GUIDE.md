# 🔐 Guia Avançado: SSH Tunnel

Este guia explica como configurar e usar SSH Tunnel corretamente com o painel GOST.

---

## ⚠️ **Importante: SSH é Diferente**

SSH **NÃO** funciona como outros protocolos (Shadowsocks, VMess, etc):
- ❌ Não funciona em apps VPN mobile (v2rayNG, Shadowrocket)
- ❌ Não tem QR Code
- ✅ Requer autenticação SSH (usuário + senha ou chave)
- ✅ Funciona apenas em clientes SSH específicos

---

## 🎯 **Quando Usar SSH Tunnel**

### ✅ **Bom para:**
- Acesso remoto ao servidor
- Port forwarding específico
- Túneis temporários
- Debugging
- Ambientes corporativos (SSH geralmente permitido)

### ❌ **Não use para:**
- VPN mobile (use SOCKS5, Shadowsocks, VMess)
- Navegação web simples (use HTTP, SOCKS5)
- Streaming (use protocolos mais rápidos)

---

## 🔧 **Configuração no Servidor**

### **Opção 1: Usar SSH Nativo do Ubuntu (Recomendado)**

```bash
# 1. Editar config SSH
sudo nano /etc/ssh/sshd_config

# 2. Adicionar/modificar linhas:
Port 22
Port 2222  # Porta adicional para túnel

# Permitir port forwarding
AllowTcpForwarding yes
GatewayPorts yes

# 3. Reiniciar SSH
sudo systemctl restart sshd

# 4. Abrir porta no firewall
sudo ufw allow 2222/tcp

# 5. Verificar
sudo ss -tlnp | grep 2222
```

### **Opção 2: Usar GOST como SSH Server**

⚠️ **Avançado:** GOST pode funcionar como servidor SSH, mas requer configuração manual complexa.

---

## 💻 **Como Usar SSH Tunnel**

### **Windows**

#### **PuTTY:**
1. Download: [putty.org](https://www.putty.org/)
2. Configurar:
   - Host: `138.197.212.221`
   - Port: `2222`
   - Connection → SSH → Tunnels:
     - Source port: `1080`
     - Destination: `Dynamic`
     - Add
3. Conectar com usuário/senha
4. Configurar navegador para usar SOCKS5 `localhost:1080`

#### **OpenSSH (Windows 10+):**
```powershell
# Túnel SOCKS dinâmico
ssh -D 1080 -p 2222 root@138.197.212.221

# Port forwarding específico
ssh -L 3306:localhost:3306 -p 2222 root@138.197.212.221
```

---

### **Linux/macOS**

```bash
# Túnel SOCKS dinâmico (porta local 1080)
ssh -D 1080 -p 2222 root@138.197.212.221

# Port forwarding local (MySQL exemplo)
ssh -L 3306:localhost:3306 -p 2222 root@138.197.212.221

# Port forwarding remoto
ssh -R 8080:localhost:80 -p 2222 root@138.197.212.221

# Manter conexão em background
ssh -D 1080 -p 2222 -f -N root@138.197.212.221
```

**Parâmetros:**
- `-D 1080`: Dynamic port forwarding (SOCKS proxy na porta 1080)
- `-L`: Local port forwarding
- `-R`: Remote port forwarding
- `-f`: Background
- `-N`: Não executar comando remoto
- `-p 2222`: Porta SSH

---

### **Android**

#### **ConnectBot** (Grátis)
1. Download: [Play Store](https://play.google.com/store/apps/details?id=org.connectbot)
2. Criar conexão:
   - Host: `root@138.197.212.221`
   - Port: `2222`
3. Menu → Port Forwards → Add:
   - Type: Dynamic (SOCKS)
   - Source port: `1080`
4. Conectar
5. Configurar apps para usar SOCKS5 `localhost:1080`

#### **JuiceSSH** (Grátis)
1. Download: [Play Store](https://play.google.com/store/apps/details?id=com.sonelli.juicessh)
2. Connections → New
3. Configure port forwarding

---

### **iOS**

#### **Termius** ($9.99/mês)
1. Download: [App Store](https://apps.apple.com/app/termius/id549039908)
2. Criar conexão SSH
3. Configurar port forwarding

⚠️ **Limitação iOS:** Port forwarding é limitado, melhor usar SOCKS5 ou Shadowsocks.

---

## 🔐 **Autenticação**

### **Senha (Simples)**
```bash
ssh -D 1080 -p 2222 root@138.197.212.221
# Digite a senha quando solicitado
```

### **Chave SSH (Recomendado)**

```bash
# 1. Gerar chave (se não tiver)
ssh-keygen -t ed25519 -C "seu@email.com"

# 2. Copiar chave para servidor
ssh-copy-id -p 2222 root@138.197.212.221

# 3. Conectar sem senha
ssh -D 1080 -p 2222 root@138.197.212.221
```

---

## 🌐 **Configurar Navegador**

### **Firefox:**
1. Settings → Network Settings
2. Manual proxy configuration
3. SOCKS Host: `localhost`
4. Port: `1080`
5. SOCKS v5: ✅
6. Proxy DNS: ✅

### **Chrome/Edge:**
```bash
# Windows
chrome.exe --proxy-server="socks5://localhost:1080"

# Linux
google-chrome --proxy-server="socks5://localhost:1080"
```

### **Sistema (Windows):**
1. Settings → Network & Internet → Proxy
2. Manual proxy setup
3. Use a proxy server: ON
4. Address: `localhost`
5. Port: `1080`

---

## 📱 **Proxychains (Linux/Android)**

```bash
# Instalar
sudo apt install proxychains4

# Configurar
sudo nano /etc/proxychains4.conf

# Adicionar:
socks5 127.0.0.1 1080

# Usar
proxychains4 curl https://api.ipify.org
proxychains4 firefox
```

---

## 🎯 **Casos de Uso Avançados**

### **1. Túnel Reverso (Expor porta local)**
```bash
# Servidor pode acessar sua porta local 8080
ssh -R 8080:localhost:8080 -p 2222 root@138.197.212.221
```

### **2. Múltiplos Port Forwards**
```bash
ssh -L 3306:localhost:3306 \
    -L 5432:localhost:5432 \
    -L 6379:localhost:6379 \
    -p 2222 root@138.197.212.221
```

### **3. Jump Host (Bastion)**
```bash
# Conectar através do servidor
ssh -J root@138.197.212.221:2222 user@internal-server
```

### **4. SOCKS Proxy Persistente**
```bash
# Criar serviço systemd
sudo nano /etc/systemd/system/ssh-tunnel.service

[Unit]
Description=SSH Tunnel
After=network.target

[Service]
ExecStart=/usr/bin/ssh -D 1080 -p 2222 -N root@138.197.212.221
Restart=always
User=youruser

[Install]
WantedBy=multi-user.target

# Ativar
sudo systemctl enable ssh-tunnel
sudo systemctl start ssh-tunnel
```

---

## 🔍 **Troubleshooting**

### **Conexão recusada**
```bash
# Verificar se SSH está rodando
sudo systemctl status sshd

# Verificar porta
sudo ss -tlnp | grep 2222

# Verificar firewall
sudo ufw status
```

### **Autenticação falha**
```bash
# Ver logs SSH
sudo tail -f /var/log/auth.log

# Testar conexão
ssh -v -p 2222 root@138.197.212.221
```

### **Túnel não funciona**
```bash
# Verificar se port forwarding está habilitado
grep AllowTcpForwarding /etc/ssh/sshd_config

# Testar túnel
curl --socks5 localhost:1080 https://api.ipify.org
```

---

## 📊 **Comparação: SSH vs Outros Protocolos**

| Característica | SSH | SOCKS5 | Shadowsocks | VMess |
|----------------|-----|--------|-------------|-------|
| Mobile Apps | ❌ | ✅ | ✅ | ✅ |
| QR Code | ❌ | ✅ | ✅ | ✅ |
| Autenticação | Usuário+Senha | Opcional | Senha | UUID |
| Port Forward | ✅ Avançado | ❌ | ❌ | ❌ |
| Acesso Remoto | ✅ | ❌ | ❌ | ❌ |
| Velocidade | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Segurança | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 💡 **Recomendação**

**Para uso mobile/VPN:** Use SOCKS5, Shadowsocks, VMess ou Trojan  
**Para port forwarding:** Use SSH  
**Para acesso remoto:** Use SSH  
**Para máxima compatibilidade:** Use SOCKS5

---

**SSH é uma ferramenta poderosa para usuários avançados!** 🔐🚀
