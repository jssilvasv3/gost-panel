# 🌐 Guia: Adicionar Domínio ao Servidor GOST

## 📋 Pré-requisitos

- ✅ VPS funcionando (138.197.212.221)
- ✅ Painel GOST ativo
- ⬜ Domínio registrado (ex: `meuproxy.com`)

---

## 🎯 Benefícios de Usar Domínio

1. **SSL Válido (Let's Encrypt)** - Certificados gratuitos e confiáveis
2. **Mais Profissional** - `proxy.seudominio.com` vs `138.197.212.221`
3. **Bypass de Bloqueios** - IPs são bloqueados mais facilmente que domínios
4. **Trojan/VLESS Funcionam Melhor** - Requerem SNI (Server Name Indication)
5. **Painel Web com HTTPS** - Acesso seguro ao painel

---

## 🛒 Passo 1: Registrar um Domínio

### Opções Recomendadas:

| Registrador | Preço/ano | Privacidade | Recomendação |
|-------------|-----------|-------------|--------------|
| **Namecheap** | $8-12 | Grátis | ⭐⭐⭐⭐⭐ Melhor custo-benefício |
| **Cloudflare** | $9-10 | Grátis | ⭐⭐⭐⭐⭐ Melhor DNS |
| **Porkbun** | $7-10 | Grátis | ⭐⭐⭐⭐ Barato |
| **GoDaddy** | $12-20 | Pago | ⭐⭐⭐ Mais caro |

**Recomendação:** Use **Namecheap** ou **Cloudflare**.

**TLDs recomendados:**
- `.com` - Mais confiável ($10-12/ano)
- `.net` - Alternativa boa ($10-12/ano)
- `.xyz` - Muito barato ($1-3/ano)
- `.online` - Barato ($3-5/ano)

---

## 🔧 Passo 2: Configurar DNS

### Opção A: DNS do Registrador (Simples)

**No painel do Namecheap/Cloudflare:**

1. Vá em **DNS Management** / **Gerenciar DNS**
2. Adicione estes registros:

```
Tipo    Nome    Valor                   TTL
A       @       138.197.212.221         300
A       *       138.197.212.221         300
CNAME   www     @                       300
CNAME   panel   @                       300
CNAME   proxy   @                       300
```

**Explicação:**
- `@` = domínio raiz (`meuproxy.com`)
- `*` = wildcard (qualquer subdomínio)
- `panel` = painel web (`panel.meuproxy.com`)
- `proxy` = servidor proxy (`proxy.meuproxy.com`)

### Opção B: Cloudflare DNS (Recomendado)

**Vantagens:**
- ✅ DNS mais rápido do mundo
- ✅ DDoS protection gratuito
- ✅ CDN gratuito
- ✅ SSL flexível

**Configuração:**

1. Crie conta em [cloudflare.com](https://cloudflare.com)
2. Clique em **Add Site** / **Adicionar Site**
3. Digite seu domínio: `meuproxy.com`
4. Escolha plano **Free**
5. Cloudflare vai escanear seus DNS atuais
6. Adicione os registros:

```
Tipo    Nome    Conteúdo            Proxy   TTL
A       @       138.197.212.221     ❌      Auto
A       panel   138.197.212.221     ❌      Auto
A       proxy   138.197.212.221     ❌      Auto
A       *       138.197.212.221     ❌      Auto
```

⚠️ **IMPORTANTE:** Deixe **Proxy OFF** (nuvem cinza) para proxies funcionarem!

7. Copie os **nameservers** do Cloudflare (ex: `ns1.cloudflare.com`)
8. Volte ao Namecheap e mude os nameservers para os do Cloudflare
9. Aguarde 1-24 horas para propagação

---

## 🔐 Passo 3: Instalar SSL (Let's Encrypt)

### Instalar Certbot na VPS:

```bash
# Instalar Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# Gerar certificado SSL
sudo certbot --nginx -d meuproxy.com -d www.meuproxy.com -d panel.meuproxy.com -d proxy.meuproxy.com

# Durante a instalação:
# - Email: seu@email.com
# - Aceitar termos: Y
# - Compartilhar email: N
# - Redirecionar HTTP para HTTPS: 2 (Yes)

# Verificar renovação automática
sudo certbot renew --dry-run
```

**Certificados serão salvos em:**
- `/etc/letsencrypt/live/meuproxy.com/fullchain.pem`
- `/etc/letsencrypt/live/meuproxy.com/privkey.pem`

---

## 🌐 Passo 4: Configurar Nginx com Domínio

Edite a configuração do Nginx:

```bash
sudo nano /etc/nginx/sites-available/gost-panel
```

**Substitua por:**

```nginx
# Redirecionar HTTP para HTTPS
server {
    listen 80;
    server_name meuproxy.com www.meuproxy.com panel.meuproxy.com;
    return 301 https://$server_name$request_uri;
}

# Painel HTTPS
server {
    listen 443 ssl http2;
    server_name panel.meuproxy.com;

    ssl_certificate /etc/letsencrypt/live/meuproxy.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meuproxy.com/privkey.pem;
    
    # SSL otimizado
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Página inicial (opcional)
server {
    listen 443 ssl http2;
    server_name meuproxy.com www.meuproxy.com;

    ssl_certificate /etc/letsencrypt/live/meuproxy.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meuproxy.com/privkey.pem;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

**Aplicar configuração:**

```bash
# Testar configuração
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx
```

---

## 🔧 Passo 5: Atualizar Configurações do GOST

### Atualizar certificados TLS do GOST:

```bash
# Copiar certificados Let's Encrypt para GOST
sudo cp /etc/letsencrypt/live/meuproxy.com/fullchain.pem /etc/gost/certs/server.crt
sudo cp /etc/letsencrypt/live/meuproxy.com/privkey.pem /etc/gost/certs/server.key
sudo chown gost:gost /etc/gost/certs/*

# Reiniciar GOST
sudo systemctl restart gost
```

### Criar script de renovação automática:

```bash
sudo nano /etc/letsencrypt/renewal-hooks/deploy/gost-update.sh
```

**Conteúdo:**

```bash
#!/bin/bash
# Atualizar certificados GOST após renovação Let's Encrypt

cp /etc/letsencrypt/live/meuproxy.com/fullchain.pem /etc/gost/certs/server.crt
cp /etc/letsencrypt/live/meuproxy.com/privkey.pem /etc/gost/certs/server.key
chown gost:gost /etc/gost/certs/*
systemctl restart gost
```

**Dar permissão:**

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/gost-update.sh
```

---

## 📱 Passo 6: Atualizar Apps Mobile

### Trojan (v2rayNG):

**Antes:**
```
trojan://senha@138.197.212.221:8443
```

**Depois:**
```
trojan://senha@proxy.meuproxy.com:8443?sni=proxy.meuproxy.com#MeuProxy
```

### VMess (v2rayNG):

Edite a conexão:
- **Address:** `proxy.meuproxy.com`
- **Port:** `10086`
- **TLS:** `tls`
- **SNI:** `proxy.meuproxy.com`

### VLESS (v2rayNG):

Edite a conexão:
- **Address:** `proxy.meuproxy.com`
- **Port:** `10087`
- **TLS:** `tls`
- **SNI:** `proxy.meuproxy.com`

---

## ✅ Passo 7: Testar Tudo

### Teste 1: DNS propagado?

```bash
# No Windows PowerShell
nslookup meuproxy.com
nslookup panel.meuproxy.com
nslookup proxy.meuproxy.com

# Deve retornar: 138.197.212.221
```

### Teste 2: SSL funcionando?

```bash
# Testar SSL
curl -I https://panel.meuproxy.com

# Deve retornar: HTTP/2 200
```

### Teste 3: Painel acessível?

Abra no navegador:
- `https://panel.meuproxy.com` ✅

### Teste 4: Proxies funcionando?

```bash
# Testar SOCKS5
curl -x socks5://proxy.meuproxy.com:1081 https://api.ipify.org

# Deve retornar o IP da VPS
```

---

## 🎯 Configuração Final Recomendada

### Estrutura de Subdomínios:

```
meuproxy.com              → Página inicial (opcional)
panel.meuproxy.com        → Painel GOST (HTTPS)
proxy.meuproxy.com        → Servidor proxy (todos os protocolos)
api.meuproxy.com          → API REST (opcional)
```

### Portas Expostas:

```
443  → Nginx (HTTPS para painel)
80   → Nginx (redireciona para HTTPS)
1080 → SOCKS4
1081 → SOCKS5
8080 → HTTP Proxy
8082 → WSS
8083 → HTTP/2
8085 → H2C
8086 → gRPC
8087 → QUIC
8088 → KCP
8389 → Shadowsocks
8443 → Trojan
9000-9101 → Túneis especiais
10086 → VMess
10087 → VLESS
2222 → SSH
```

---

## 🔒 Segurança Adicional

### Firewall (UFW):

```bash
# Permitir apenas portas necessárias
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1080:10087/tcp
sudo ufw allow 2222/tcp
sudo ufw enable
```

### Fail2Ban (proteção contra brute force):

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 📊 Monitoramento

### Ver logs do Nginx:

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Ver logs do Certbot:

```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Verificar renovação SSL:

```bash
sudo certbot certificates
```

---

## 🆘 Troubleshooting

### Problema: DNS não propaga

**Solução:**
```bash
# Verificar DNS
dig meuproxy.com @8.8.8.8
dig panel.meuproxy.com @8.8.8.8

# Limpar cache DNS local (Windows)
ipconfig /flushdns
```

### Problema: SSL não funciona

**Solução:**
```bash
# Verificar certificados
sudo certbot certificates

# Renovar manualmente
sudo certbot renew --force-renewal

# Verificar Nginx
sudo nginx -t
sudo systemctl status nginx
```

### Problema: Trojan não conecta

**Solução:**
- Verificar SNI está configurado: `sni=proxy.meuproxy.com`
- Verificar certificado TLS está válido
- Testar com `allowInsecure=true` temporariamente

---

## 💰 Custos Estimados

| Item | Custo/ano | Necessário? |
|------|-----------|-------------|
| Domínio .com | $10-12 | ✅ Sim |
| Domínio .xyz | $1-3 | ✅ Alternativa |
| Cloudflare Free | $0 | ⬜ Opcional |
| Let's Encrypt SSL | $0 | ✅ Grátis |
| VPS DigitalOcean | $60-120 | ✅ Já tem |

**Total:** $10-12/ano (apenas domínio)

---

## 🎉 Resultado Final

Após configurar tudo:

✅ Painel acessível em: `https://panel.meuproxy.com`  
✅ SSL válido e confiável  
✅ Proxies funcionando com domínio  
✅ Renovação automática de SSL  
✅ Mais profissional e seguro  

---

**Última atualização:** 26 de Novembro de 2025  
**Dificuldade:** ⭐⭐⭐ Intermediário  
**Tempo estimado:** 30-60 minutos
