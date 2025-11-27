# 🚀 GOST Panel - Painel de Gerenciamento Completo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04-orange)](https://ubuntu.com/)
[![GOST](https://img.shields.io/badge/GOST-3.0-blue)](https://github.com/go-gost/gost)

Painel web completo para gerenciamento de túneis GOST, Shadowsocks e Xray com suporte a **27 protocolos diferentes**.

![GOST Panel](https://via.placeholder.com/800x400.png?text=GOST+Panel+Screenshot)

---

## ✨ Características

### 🔌 **27 Protocolos Suportados**

- **GOST (18 protocolos):** SOCKS5, SOCKS4, HTTP, WSS, HTTP/2, H2C, gRPC, QUIC, KCP, TCP, UDP, RTCP, RUDP, TLS, DTLS, RELAY, FORWARD, API
- **Shadowsocks (1 protocolo):** SS (aes-256-gcm)
- **Xray (3 protocolos):** VMess, VLESS, Trojan
- **SSH (1 protocolo):** SSH Tunnel
- **Avançados (4 protocolos):** DNS, DoH, DoT, ICMP

### 🎯 **Recursos do Painel**

- ✅ **Interface Web Moderna** - Design responsivo e intuitivo
- ✅ **Criação Automática** - Gera credenciais e configurações automaticamente
- ✅ **QR Codes** - Para Shadowsocks, VMess, VLESS e Trojan
- ✅ **Chain Multi-Hop** - Encadeamento de proxies
- ✅ **Load Balancing** - Balanceamento de carga entre múltiplos servidores
- ✅ **API REST** - Gerenciamento programático
- ✅ **Logs Centralizados** - Via systemd journalctl
- ✅ **SSL/TLS** - Suporte a certificados Let's Encrypt

### ⚡ **Performance**

- ✅ **BBR Ativado** - TCP otimizado para máxima velocidade
- ✅ **Buffers Otimizados** - Configuração de rede de alta performance
- ✅ **Protocolos Rápidos** - KCP, QUIC, RUDP para baixa latência

---

## 🚀 Instalação Rápida (1 Comando)

### **Ubuntu 20.04/22.04 LTS**

```bash
wget -qO- https://raw.githubusercontent.com/jssilvasv3/gost-panel/main/auto_install.sh | sudo bash
```

**Isso vai instalar:**
- GOST + Shadowsocks + Xray
- Painel Web Python Flask
- Nginx com SSL
- Otimizações de rede (BBR)
- Firewall configurado
- Todos os 27 protocolos

**Tempo estimado:** 5-10 minutos

---

## 📋 Instalação Manual

### 1. Clonar Repositório

```bash
cd /opt
git clone https://github.com/jssilvasv3/gost-panel.git
cd gost-panel
```

### 2. Executar Instalador

```bash
chmod +x auto_install.sh
sudo ./auto_install.sh
```

### 3. Acessar Painel

```
URL: http://SEU_IP
Usuário: admin
Senha: admin123
```

⚠️ **Altere a senha padrão imediatamente!**

---

## 📱 Uso

### **Criar Novo Túnel**

1. Acesse o painel web
2. Clique em **"Criar Regra"**
3. Escolha o protocolo (ex: SOCKS5, VMess, Trojan)
4. Clique em **"Criar"** (credenciais são geradas automaticamente)
5. Clique em **"Aplicar Configuração"**
6. Use o QR Code no app mobile ou copie as credenciais

### **Apps Recomendados**

| Plataforma | App | Protocolos |
|------------|-----|------------|
| **Android** | v2rayNG | Todos |
| **iOS** | Shadowrocket | Todos |
| **Windows** | v2rayN | Todos |
| **macOS** | ClashX | Todos |
| **Linux** | Clash | Todos |

---

## 🔧 Configuração Avançada

### **Adicionar Domínio**

```bash
# Instalar SSL Let's Encrypt
sudo certbot --nginx -d seudominio.com -d panel.seudominio.com

# Atualizar certificados GOST
sudo cp /etc/letsencrypt/live/seudominio.com/fullchain.pem /etc/gost/certs/server.crt
sudo cp /etc/letsencrypt/live/seudominio.com/privkey.pem /etc/gost/certs/server.key
sudo systemctl restart gost
```

Veja [DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md) para detalhes.

### **Otimizar Performance**

```bash
# BBR já vem ativado, mas você pode otimizar mais:
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
```

Veja [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md) para detalhes.

---

## 📚 Documentação

| Guia | Descrição |
|------|-----------|
| [PROTOCOLS_GUIDE.md](PROTOCOLS_GUIDE.md) | Guia completo de todos os protocolos |
| [APPS_GUIDE.md](APPS_GUIDE.md) | Apps para cada plataforma |
| [MOBILE_SETUP_GUIDE.md](MOBILE_SETUP_GUIDE.md) | Setup mobile passo a passo |
| [SSH_ADVANCED_GUIDE.md](SSH_ADVANCED_GUIDE.md) | SSH para usuários avançados |
| [DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md) | Como adicionar domínio |
| [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md) | Otimizações de velocidade |
| [API_DOCUMENTATION.md](API_DOCUMENTATION.md) | API REST completa |

---

## 🛠️ Gerenciamento

### **Comandos Úteis**

```bash
# Ver status dos serviços
sudo systemctl status gost
sudo systemctl status gost-panel
sudo systemctl status shadowsocks-libev-server@config
sudo systemctl status xray

# Ver logs
sudo journalctl -u gost -f
sudo journalctl -u gost-panel -f

# Reiniciar serviços
sudo systemctl restart gost
sudo systemctl restart gost-panel

# Ver portas abertas
sudo ss -tlnpu | grep gost

# Ver uso de banda
sudo iftop -i eth0
```

### **Arquivos Importantes**

```
/etc/gost/config.json                    # Config GOST
/etc/gost/certs/                         # Certificados SSL
/opt/gost-panel/panel.db                 # Banco de dados
/opt/gost-panel/panel/app.py             # Código do painel
/etc/shadowsocks-libev/config.json       # Config Shadowsocks
/usr/local/etc/xray/config.json          # Config Xray
```

---

## 🔒 Segurança

### **Firewall (UFW)**

```bash
# Ver regras
sudo ufw status

# Permitir nova porta
sudo ufw allow 12345/tcp
```

### **Fail2Ban**

```bash
# Ver status
sudo fail2ban-client status

# Ver IPs banidos
sudo fail2ban-client status sshd
```

### **Alterar Senha do Painel**

1. Acesse: `http://SEU_IP`
2. Login com `admin / admin123`
3. Vá em **Configurações**
4. Altere a senha

---

## 📊 Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                     Cliente (Mobile/PC)                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                    Nginx (Port 80/443)                  │
│                    - SSL/TLS                            │
│                    - Reverse Proxy                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              GOST Panel (Port 5000)                     │
│              - Python Flask                             │
│              - SQLite Database                          │
│              - QR Code Generator                        │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┼───────────┬───────────┐
         ▼           ▼           ▼           ▼
    ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
    │  GOST  │  │Shadow- │  │  Xray  │  │  SSH   │
    │18 Proto│  │ socks  │  │3 Proto │  │Tunnel  │
    └────────┘  └────────┘  └────────┘  └────────┘
```

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📝 Changelog

### v2.0.0 (2025-11-26)
- ✨ Suporte a 27 protocolos
- ✨ Auto-instalador completo
- ✨ BBR ativado por padrão
- ✨ QR Codes para todos os protocolos
- ✨ Chain Multi-Hop
- ✨ Load Balancing
- 🐛 Correções de bugs
- 📚 Documentação completa

### v1.0.0 (2025-11-20)
- 🎉 Versão inicial
- ✨ Suporte a GOST, Shadowsocks, Xray
- ✨ Painel web básico

---

## 🆘 Suporte

### **Problemas Comuns**

**Painel não abre:**
```bash
sudo systemctl status gost-panel
sudo journalctl -u gost-panel -n 50
```

**GOST não inicia:**
```bash
sudo systemctl status gost
sudo journalctl -u gost -n 50
```

**Porta já em uso:**
```bash
sudo ss -tlnpu | grep :PORTA
sudo kill -9 PID
```

### **Obter Ajuda**

- 📖 Leia a [Documentação](PROTOCOLS_GUIDE.md)
- 🐛 Abra uma [Issue](https://github.com/SEU_USUARIO/gost-panel/issues)
- 💬 Discussões no [GitHub Discussions](https://github.com/SEU_USUARIO/gost-panel/discussions)

---

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 🙏 Agradecimentos

- [GOST](https://github.com/go-gost/gost) - Túnel proxy em Go
- [Xray](https://github.com/XTLS/Xray-core) - Plataforma de proxy
- [Shadowsocks](https://shadowsocks.org/) - Proxy SOCKS5 seguro
- [Flask](https://flask.palletsprojects.com/) - Framework web Python

---

## 📞 Contato

- **GitHub:** [@SEU_USUARIO](https://github.com/SEU_USUARIO)
- **Email:** seu@email.com

---

<div align="center">

**⭐ Se este projeto foi útil, deixe uma estrela! ⭐**

Made with ❤️ by [Seu Nome]

</div>
