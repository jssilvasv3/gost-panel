# GOST Panel - Guia de Desenvolvimento Local

Este guia explica como executar o painel GOST localmente no Windows para desenvolvimento e testes antes da implantação na VPS.

## 📋 Requisitos

- **Windows 10/11**
- **Python 3.8 ou superior** - [Download](https://www.python.org/downloads/)
- **Navegador web** (Chrome, Firefox, Edge, etc.)

## 🚀 Instalação Rápida

### 1. Configurar Ambiente

Execute o script de setup para criar o ambiente virtual e instalar dependências:

```batch
setup_local.bat
```

Este script irá:
- ✅ Verificar instalação do Python
- ✅ Criar ambiente virtual Python
- ✅ Instalar todas as dependências
- ✅ Criar diretórios necessários (`local_data/`, `local_config/`)

### 2. Iniciar o Servidor

Execute o script para iniciar o painel:

```batch
run_local.bat
```

O navegador abrirá automaticamente em `http://localhost:5000`

### 3. Fazer Login

Use as credenciais padrão:
- **Usuário:** `admin`
- **Senha:** `admin`

> [!WARNING]
> **Importante:** Altere a senha padrão após o primeiro login!

## 📂 Estrutura de Arquivos

```
gost_full_package/
├── panel/
│   ├── app.py                    # Versão original (VPS)
│   ├── app_local.py              # 🆕 Versão local (Windows)
│   ├── local_data/               # 🆕 Dados locais
│   │   └── panel.db              # Banco de dados SQLite
│   ├── local_config/             # 🆕 Configurações locais
│   │   └── config.json           # Config GOST gerado
│   ├── routes/                   # Rotas Flask
│   ├── templates/                # Templates HTML
│   └── requirements.txt          # Dependências Python
├── setup_local.bat               # 🆕 Script de setup
├── run_local.bat                 # 🆕 Script de execução
└── README_LOCAL.md               # 🆕 Este arquivo
```

## 🎯 Funcionalidades Disponíveis

### ✅ Totalmente Funcionais

- **Autenticação:** Login/logout com hash SHA256
- **CRUD de Regras:** Criar, listar e deletar regras de túnel
- **Geração de QR Codes:** Para SOCKS5, Shadowsocks, VMess, VLESS
- **Aplicar Configuração:** Gera `config.json` válido para GOST
- **Interface Web:** Todas as páginas e templates funcionam

### ⚠️ Simulado (Mock)

- **Restart do GOST:** Comando `systemctl restart gost` é simulado
  - No modo local, apenas exibe mensagem no console
  - Na VPS, executa o comando real

### ❌ Não Disponível Localmente

- **Executável GOST:** Não é instalado/executado localmente
- **Nginx:** Acesso direto via Flask (porta 5000)
- **SSL/HTTPS:** Apenas HTTP no modo local
- **Systemd Services:** Não aplicável no Windows

## 🔧 Uso Detalhado

### Criar Nova Regra de Túnel

1. Acesse o painel em `http://localhost:5000`
2. Clique em **"Criar Nova Regra"**
3. Preencha os campos:
   - **Nome:** Identificador da regra
   - **Protocolo:** socks5, ss, vmess, vless, etc.
   - **Listen:** Endereço de escuta (ex: `:8080`)
   - **Target:** Destino do túnel (ex: `example.com:80`)
   - **Password:** Senha (se aplicável)
   - **Extra:** Parâmetros adicionais (método de criptografia, UUID, etc.)
4. Clique em **"Criar"**

### Gerar QR Code

1. Na lista de regras, clique no botão **"QR"**
2. O QR code será gerado automaticamente
3. Use aplicativos móveis compatíveis para escanear:
   - **SOCKS5:** Shadowrocket, Surge, etc.
   - **Shadowsocks:** Shadowsocks Android/iOS
   - **VMess/VLESS:** V2RayNG, V2RayN, etc.

### Aplicar Configuração

1. Após criar/modificar regras, clique em **"Aplicar Configuração"**
2. O sistema gera `local_config/config.json` com todas as regras
3. No modo local, o restart é simulado
4. Verifique o arquivo gerado em: `panel/local_config/config.json`

### Visualizar Configuração Gerada

Abra o arquivo gerado para verificar a sintaxe:

```batch
notepad panel\local_config\config.json
```

Exemplo de configuração gerada:

```json
{
  "servers": [
    {
      "name": "Meu Túnel SOCKS5",
      "listen": ":8080",
      "forward": "example.com:80"
    }
  ],
  "metrics": {
    "listen": "127.0.0.1:9090"
  }
}
```

## 🔄 Migração para VPS

### Exportar Configurações

1. Copie o banco de dados local:
   ```batch
   copy panel\local_data\panel.db panel\panel.db
   ```

2. Faça upload do pacote completo para a VPS:
   ```bash
   scp -r gost_full_package/ user@vps:/root/
   ```

3. Execute o instalador na VPS:
   ```bash
   sudo bash install.sh --domain seu.dominio.com --email seu@email.com
   ```

### Diferenças VPS vs Local

| Recurso | Local (Windows) | VPS (Linux) |
|---------|----------------|-------------|
| Banco de dados | `local_data/panel.db` | `/opt/gost-panel/panel.db` |
| Configuração GOST | `local_config/config.json` | `/etc/gost/config.json` |
| Restart serviço | Simulado (mock) | `systemctl restart gost` |
| Acesso web | `http://localhost:5000` | `https://seu.dominio.com` |
| SSL/HTTPS | Não | Sim (via Certbot) |
| Nginx | Não | Sim (reverse proxy) |

## 🐛 Troubleshooting

### Erro: "Python não encontrado"

**Solução:** Instale Python 3.8+ de [python.org](https://www.python.org/downloads/)

Durante a instalação, marque a opção **"Add Python to PATH"**

### Erro: "pip install falhou"

**Solução:** Atualize o pip e tente novamente:

```batch
cd panel
venv\Scripts\activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### Erro: "Porta 5000 já em uso"

**Solução:** Outra aplicação está usando a porta 5000. Opções:

1. Feche a aplicação que está usando a porta
2. Ou modifique `app_local.py` linha 247:
   ```python
   app.run(host='0.0.0.0', port=5001, debug=True)  # Use porta 5001
   ```

### Erro: "ModuleNotFoundError: No module named 'flask'"

**Solução:** O ambiente virtual não foi ativado. Execute:

```batch
cd panel
venv\Scripts\activate
python app_local.py
```

### Banco de dados corrompido

**Solução:** Delete e recrie o banco:

```batch
del panel\local_data\panel.db
run_local.bat
```

O banco será recriado automaticamente com credenciais padrão.

## 🔐 Segurança

### Alterar Senha do Admin

1. Faça login com credenciais padrão
2. No futuro, implementaremos página de configurações
3. Por enquanto, use o script `create_admin_sha.py`:

```batch
cd panel
venv\Scripts\activate
python create_admin_sha.py
```

### Proteger Acesso Local

O servidor Flask escuta em `0.0.0.0:5000`, permitindo acesso de outros dispositivos na rede local.

Para restringir apenas ao localhost, modifique `app_local.py` linha 247:

```python
app.run(host='127.0.0.1', port=5000, debug=True)  # Apenas localhost
```

## 📚 Recursos Adicionais

- **Documentação GOST:** [https://gost.run](https://gost.run)
- **Flask Documentation:** [https://flask.palletsprojects.com](https://flask.palletsprojects.com)
- **Protocolos Suportados:** Veja `panel/routes/protocols.py`

## 🆘 Suporte

Para problemas ou dúvidas:

1. Verifique a seção **Troubleshooting** acima
2. Consulte os logs do Flask no terminal
3. Verifique os arquivos gerados em `local_config/` e `local_data/`

## 📝 Notas de Desenvolvimento

### Modo Debug

O modo debug está **ativado** em `app_local.py`:
- ✅ Auto-reload ao modificar código
- ✅ Mensagens de erro detalhadas
- ✅ Debugger interativo no navegador

### Estrutura do Código

- **`app_local.py`:** Aplicação Flask principal
- **`routes/protocols.py`:** Rotas para página de protocolos
- **`templates/`:** Templates Jinja2 para HTML
- **`local_data/`:** Banco de dados SQLite
- **`local_config/`:** Configurações GOST geradas

### Adicionar Novos Recursos

1. Modifique `app_local.py` ou crie novas rotas em `routes/`
2. Atualize templates em `templates/`
3. Teste localmente com `run_local.bat`
4. Aplique mudanças em `app.py` para VPS

---

**Desenvolvido para facilitar testes locais antes da implantação em VPS** 🚀
