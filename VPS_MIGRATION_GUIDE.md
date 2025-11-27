# GOST Panel - Guia de Migração para VPS

Este guia explica como migrar o painel GOST com todos os recursos avançados para sua VPS Ubuntu.

## 📋 Pré-requisitos

- VPS Ubuntu 20.04/22.04
- Acesso root via SSH
- Domínio apontado para o IP da VPS (opcional, para SSL)
- Backup dos dados atuais (se houver)

## 🚀 Instalação Rápida

### 1. Fazer Upload do Pacote

```bash
# No seu computador local
cd c:\Users\JERFFESON\OneDrive\Documentos
zip -r gost_full_package.zip gost_full_package/

# Upload para VPS
scp gost_full_package.zip root@SEU_IP_VPS:/root/
```

### 2. Conectar na VPS e Instalar

```bash
# Conectar via SSH
ssh root@SEU_IP_VPS

# Descompactar
cd /root
unzip gost_full_package.zip
cd gost_full_package

# Executar instalador
sudo bash install.sh --domain seu.dominio.com --email seu@email.com

# OU sem SSL/domínio
sudo bash install.sh --no-certbot
```

### 3. Acessar o Painel

**Com domínio:**
```
https://seu.dominio.com
```

**Sem domínio:**
```
http://IP_DA_VPS:5000
```

**Credenciais padrão:**
- Usuário: `admin`
- Senha: `admin`

> [!WARNING]
> **IMPORTANTE:** Altere a senha padrão imediatamente após o primeiro login!

---

## 🔄 Migração de Dados Existentes

Se você já tem um painel GOST rodando na VPS e quer preservar os dados:

### 1. Fazer Backup

```bash
# Backup do banco de dados
sudo cp /opt/gost-panel/panel.db /root/panel.db.backup

# Backup da configuração GOST
sudo cp /etc/gost/config.json /root/config.json.backup
```

### 2. Instalar Nova Versão

```bash
# Parar serviços
sudo systemctl stop gost-panel
sudo systemctl stop gost

# Fazer backup do diretório antigo
sudo mv /opt/gost-panel /opt/gost-panel.old

# Instalar nova versão
cd /root/gost_full_package
sudo bash install.sh --domain seu.dominio.com --email seu@email.com
```

### 3. Restaurar Dados

```bash
# Parar novo painel
sudo systemctl stop gost-panel

# Restaurar banco de dados antigo
sudo cp /root/panel.db.backup /opt/gost-panel/panel.db

# Migrar banco de dados para nova estrutura
cd /opt/gost-panel
sudo -u gostsvc /opt/gost-panel/venv/bin/python3 << 'EOF'
import sqlite3

DB = "/opt/gost-panel/panel.db"
conn = sqlite3.connect(DB)
c = conn.cursor()

# Adicionar novos campos (se não existirem)
try:
    c.execute("ALTER TABLE users ADD COLUMN chain_nodes TEXT")
    print("✅ Campo chain_nodes adicionado")
except:
    print("ℹ️ Campo chain_nodes já existe")

# Criar tabela nodes
c.execute('''CREATE TABLE IF NOT EXISTS nodes
             (id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE NOT NULL,
              forward TEXT NOT NULL,
              description TEXT)''')
print("✅ Tabela nodes criada")

conn.commit()
conn.close()
print("✅ Migração concluída!")
EOF

# Reiniciar serviços
sudo systemctl start gost-panel
sudo systemctl start gost
```

---

## 🆕 Novos Recursos Disponíveis

Após a migração, você terá acesso a:

### 1. Edição de Regras
- Botão "✏️ Editar" em cada regra
- Modificar sem precisar deletar e recriar

### 2. API REST
- 10 endpoints para automação
- Autenticação por token
- Acesso: `http://seu-ip:5000/api/v1/`

### 3. Chain Multi-Hop
- Menu "🔗 Nodes" para gerenciar nodes
- Criar cadeias de múltiplos servidores
- Maior segurança e bypass de firewalls

### 4. Load Balancing
- Múltiplos targets por regra
- Estratégias: round-robin, random, hash
- Alta disponibilidade automática

### 5. Dynamic Reload
- Botão "🔄 Reload" sem restart
- Mantém conexões ativas
- Aplicação mais rápida de mudanças

---

## 🔧 Configuração Pós-Instalação

### 1. Alterar Senha do Admin

```bash
cd /opt/gost-panel
sudo -u gostsvc /opt/gost-panel/venv/bin/python3 create_admin_sha.py
```

### 2. Configurar Firewall

```bash
# Permitir portas necessárias
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 5000/tcp  # Panel (se sem Nginx)

# Permitir portas dos túneis GOST
sudo ufw allow 1080:1090/tcp
sudo ufw allow 1080:1090/udp

# Ativar firewall
sudo ufw enable
```

### 3. Verificar Serviços

```bash
# Status do painel
sudo systemctl status gost-panel

# Status do GOST
sudo systemctl status gost

# Logs do painel
sudo journalctl -u gost-panel -f

# Logs do GOST
sudo journalctl -u gost -f
```

---

## 🧪 Testes Pós-Migração

### 1. Testar Painel Web
- [ ] Login funciona
- [ ] Criar nova regra
- [ ] Editar regra existente
- [ ] Deletar regra
- [ ] Aplicar configuração
- [ ] Reload sem restart

### 2. Testar Nodes (Chain Multi-Hop)
- [ ] Acessar menu Nodes
- [ ] Criar novo node
- [ ] Usar node em regra
- [ ] Aplicar e testar chain

### 3. Testar API REST
```bash
# Health check
curl http://localhost:5000/api/v1/health

# Login
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# Listar regras (use o token recebido)
curl -X GET http://localhost:5000/api/v1/rules \
  -H "Authorization: Bearer SEU_TOKEN"
```

### 4. Testar GOST
```bash
# Verificar se GOST está rodando
ps aux | grep gost

# Testar conexão (exemplo SOCKS5 na porta 1080)
curl -x socks5://localhost:1080 https://api.ipify.org
```

---

## 🐛 Troubleshooting

### Problema: Painel não inicia

```bash
# Ver logs
sudo journalctl -u gost-panel -n 50

# Verificar permissões
sudo chown -R gostsvc:gostsvc /opt/gost-panel

# Reinstalar dependências
cd /opt/gost-panel
sudo -u gostsvc /opt/gost-panel/venv/bin/pip install -r requirements.txt
```

### Problema: GOST não reinicia

```bash
# Verificar config.json
sudo cat /etc/gost/config.json | jq

# Testar manualmente
sudo -u gostsvc /usr/local/bin/gost -C /etc/gost/config.json

# Ver logs
sudo journalctl -u gost -n 50
```

### Problema: SSL não funciona

```bash
# Renovar certificado
sudo certbot renew

# Reconfigurar Nginx
sudo certbot --nginx -d seu.dominio.com
```

### Problema: Porta 5000 já em uso

```bash
# Encontrar processo
sudo lsof -i :5000

# Matar processo
sudo kill -9 PID

# Ou usar outra porta (editar /etc/systemd/system/gost-panel.service)
```

---

## 📊 Comparação: Antes vs Depois

| Recurso | Versão Antiga | Nova Versão |
|---------|---------------|-------------|
| Edição de regras | ❌ | ✅ |
| API REST | ❌ | ✅ 10 endpoints |
| Chain Multi-Hop | ❌ | ✅ |
| Load Balancing | ❌ | ✅ |
| Dynamic Reload | ❌ | ✅ |
| Rate Limiting | ⚠️ Básico | ✅ Completo |
| Formato Config | v2 | ✅ v3 (GOST 3.x) |

---

## 🔐 Segurança

### Recomendações

1. **Alterar senha padrão** imediatamente
2. **Usar SSL/HTTPS** em produção
3. **Restringir acesso** ao painel via firewall
4. **Backup regular** do banco de dados
5. **Monitorar logs** regularmente

### Backup Automático

```bash
# Criar script de backup
sudo tee /root/backup-gost.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups/gost"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup banco de dados
cp /opt/gost-panel/panel.db $BACKUP_DIR/panel_$DATE.db

# Backup config
cp /etc/gost/config.json $BACKUP_DIR/config_$DATE.json

# Manter apenas últimos 7 dias
find $BACKUP_DIR -name "*.db" -mtime +7 -delete
find $BACKUP_DIR -name "*.json" -mtime +7 -delete

echo "Backup concluído: $DATE"
EOF

# Tornar executável
sudo chmod +x /root/backup-gost.sh

# Agendar no cron (diário às 3h)
(crontab -l 2>/dev/null; echo "0 3 * * * /root/backup-gost.sh") | crontab -
```

---

## 📚 Recursos Adicionais

- **Documentação API:** Ver `API_DOCUMENTATION.md`
- **Exemplos de Uso:** Ver `walkthrough.md`
- **Documentação GOST:** https://gost.run

---

**Migração completa!** Seu painel GOST agora está rodando com todos os recursos avançados na VPS. 🚀
