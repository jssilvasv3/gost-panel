# 📦 Guia de Deploy no GitHub

## 🎯 Objetivo

Subir o projeto GOST Panel no GitHub para facilitar instalação em múltiplas VPS.

---

## 📋 Pré-requisitos

- ✅ Conta no GitHub
- ✅ Git instalado no Windows
- ✅ Projeto GOST Panel completo

---

## 🚀 Passo a Passo

### 1️⃣ **Criar Repositório no GitHub**

1. Acesse [github.com](https://github.com)
2. Clique em **"New repository"** (botão verde)
3. Preencha:
   - **Repository name:** `gost-panel`
   - **Description:** `Painel completo para gerenciamento de túneis GOST, Shadowsocks e Xray`
   - **Public** ou **Private** (sua escolha)
   - ❌ **NÃO** marque "Initialize with README" (já temos um)
4. Clique em **"Create repository"**

### 2️⃣ **Preparar Projeto Local**

Abra PowerShell na pasta do projeto:

```powershell
cd C:\Users\JERFFESON\OneDrive\Documentos\gost_full_package
```

### 3️⃣ **Inicializar Git**

```powershell
# Inicializar repositório
git init

# Adicionar todos os arquivos
git add .

# Fazer primeiro commit
git commit -m "Initial commit: GOST Panel v2.0 - 27 protocolos"
```

### 4️⃣ **Conectar ao GitHub**

**Substitua `SEU_USUARIO` pelo seu usuário do GitHub:**

```powershell
# Adicionar remote
git remote add origin https://github.com/SEU_USUARIO/gost-panel.git

# Renomear branch para main
git branch -M main

# Push inicial
git push -u origin main
```

**Se pedir autenticação:**
- Use seu **Personal Access Token** (não a senha)
- Gere em: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
- Permissões: `repo` (marque tudo)

### 5️⃣ **Atualizar README.md**

Edite `README.md` e substitua:
- `SEU_USUARIO` → seu usuário GitHub
- `seu@email.com` → seu email
- `Seu Nome` → seu nome

```powershell
# Commit das alterações
git add README.md
git commit -m "Update README with correct GitHub username"
git push
```

### 6️⃣ **Atualizar auto_install.sh**

Edite `auto_install.sh` linha ~200:

```bash
# Antes:
GIT_REPO="https://github.com/SEU_USUARIO/gost-panel.git"

# Depois:
GIT_REPO="https://github.com/seu_usuario_real/gost-panel.git"
```

```powershell
# Commit
git add auto_install.sh
git commit -m "Update installer with correct repository URL"
git push
```

---

## ✅ Verificar Upload

1. Acesse: `https://github.com/SEU_USUARIO/gost-panel`
2. Verifique se todos os arquivos estão lá:
   - ✅ `README.md`
   - ✅ `auto_install.sh`
   - ✅ `panel/app.py`
   - ✅ `scripts/`
   - ✅ Guias de documentação

---

## 🚀 Testar Instalação

### **Em uma VPS nova (Ubuntu 20.04/22.04):**

```bash
# Instalar com 1 comando
wget -qO- https://raw.githubusercontent.com/SEU_USUARIO/gost-panel/main/auto_install.sh | sudo bash
```

**Ou manualmente:**

```bash
# Clonar repositório
cd /opt
git clone https://github.com/SEU_USUARIO/gost-panel.git
cd gost-panel

# Executar instalador
chmod +x auto_install.sh
sudo ./auto_install.sh
```

---

## 📝 Fazer Atualizações

### **Quando fizer mudanças no código:**

```powershell
# Ver mudanças
git status

# Adicionar arquivos modificados
git add .

# Commit com mensagem descritiva
git commit -m "Fix: Corrigir geração de QR Code para Trojan"

# Push para GitHub
git push
```

### **Atualizar VPS com nova versão:**

```bash
# Na VPS
cd /opt/gost-panel
git pull
sudo systemctl restart gost-panel
```

---

## 🏷️ Criar Release (Opcional)

### **Para versões estáveis:**

1. No GitHub, vá em **Releases** → **Create a new release**
2. Preencha:
   - **Tag:** `v2.0.0`
   - **Title:** `GOST Panel v2.0.0 - 27 Protocolos`
   - **Description:** Changelog das mudanças
3. Clique em **Publish release**

---

## 📂 Estrutura do Repositório

```
gost-panel/
├── README.md                          # Documentação principal
├── auto_install.sh                    # Instalador automático
├── .gitignore                         # Arquivos ignorados
├── LICENSE                            # Licença MIT
│
├── panel/                             # Código do painel
│   ├── app.py                         # Aplicação Flask
│   ├── requirements.txt               # Dependências Python
│   ├── templates/                     # Templates HTML
│   ├── static/                        # CSS, JS, imagens
│   └── routes/                        # Rotas da API
│
├── scripts/                           # Scripts auxiliares
│   ├── setup_all_protocols.sh
│   ├── activate_remaining_protocols.sh
│   └── update_multi_service.sh
│
├── docs/                              # Documentação
│   ├── PROTOCOLS_GUIDE.md
│   ├── APPS_GUIDE.md
│   ├── MOBILE_SETUP_GUIDE.md
│   ├── SSH_ADVANCED_GUIDE.md
│   ├── DOMAIN_SETUP_GUIDE.md
│   ├── PERFORMANCE_OPTIMIZATION.md
│   └── API_DOCUMENTATION.md
│
└── configs/                           # Configs de exemplo
    ├── gost.example.json
    ├── shadowsocks.example.json
    └── xray.example.json
```

---

## 🔒 Segurança

### **Arquivos que NÃO devem ir para o GitHub:**

❌ `panel.db` (banco de dados)  
❌ `*.key` (chaves privadas)  
❌ `*.pem` (certificados)  
❌ Senhas ou tokens  

**Esses já estão no `.gitignore`!**

### **Se acidentalmente commitou algo sensível:**

```powershell
# Remover do histórico
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch panel.db" \
  --prune-empty --tag-name-filter cat -- --all

# Force push
git push origin --force --all
```

---

## 🌟 Melhorar Visibilidade

### **Adicionar Topics no GitHub:**

1. No repositório, clique em ⚙️ (Settings)
2. Em **Topics**, adicione:
   - `gost`
   - `proxy`
   - `shadowsocks`
   - `xray`
   - `v2ray`
   - `vpn`
   - `tunnel`
   - `python`
   - `flask`

### **Adicionar Badges no README:**

Já incluídos:
- ✅ License
- ✅ Ubuntu version
- ✅ GOST version

### **Criar GitHub Pages (Opcional):**

Para hospedar documentação:

1. Settings → Pages
2. Source: `main` branch, `/docs` folder
3. Save

Documentação ficará em: `https://SEU_USUARIO.github.io/gost-panel`

---

## 📊 Estatísticas

Após publicar, você pode ver:
- 👁️ **Views** - Quantas pessoas visitaram
- ⭐ **Stars** - Quantas pessoas favoritaram
- 🍴 **Forks** - Quantas pessoas clonaram
- 📥 **Clones** - Downloads do repositório

---

## 🆘 Problemas Comuns

### **Erro: "Permission denied (publickey)"**

**Solução:** Use HTTPS ao invés de SSH:

```powershell
git remote set-url origin https://github.com/SEU_USUARIO/gost-panel.git
```

### **Erro: "Updates were rejected"**

**Solução:** Pull antes de push:

```powershell
git pull origin main --rebase
git push
```

### **Arquivo muito grande**

GitHub tem limite de 100MB por arquivo.

**Solução:** Não commitar arquivos grandes (binários, logs, etc)

---

## ✅ Checklist Final

Antes de publicar:

- [ ] README.md atualizado com seu usuário
- [ ] auto_install.sh com URL correta do repo
- [ ] .gitignore configurado
- [ ] Sem arquivos sensíveis (senhas, keys)
- [ ] Todos os scripts com permissão de execução
- [ ] Documentação completa
- [ ] Testado em VPS limpa

---

## 🎉 Pronto!

Agora você pode instalar em qualquer VPS com:

```bash
wget -qO- https://raw.githubusercontent.com/SEU_USUARIO/gost-panel/main/auto_install.sh | sudo bash
```

**Compartilhe o link do repositório!** 🚀

---

**Última atualização:** 26 de Novembro de 2025
