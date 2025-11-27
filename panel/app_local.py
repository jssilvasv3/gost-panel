#!/usr/bin/env python3
"""
GOST Panel - Local Development Version
Adapted for Windows development environment
"""
import os, sqlite3, json, subprocess, qrcode, io, base64, secrets, hashlib
from flask import Flask, render_template, request, redirect, url_for, send_file, flash, session, abort
from routes.protocols import protocols_bp
from routes.api import api_bp

# Local development paths (Windows compatible)
APP_DIR = os.path.dirname(os.path.abspath(__file__))
LOCAL_DATA_DIR = os.path.join(APP_DIR, "local_data")
LOCAL_CONFIG_DIR = os.path.join(APP_DIR, "local_config")

DB = os.path.join(LOCAL_DATA_DIR, "panel.db")
CONF = os.path.join(LOCAL_CONFIG_DIR, "config.json")
CFG_PANEL = os.path.join(APP_DIR, "panel.conf.json")

# Create local directories if they don't exist
os.makedirs(LOCAL_DATA_DIR, exist_ok=True)
os.makedirs(LOCAL_CONFIG_DIR, exist_ok=True)

app = Flask(__name__)
app.config['DB_PATH'] = DB  # For API blueprint access
app.register_blueprint(protocols_bp)
app.register_blueprint(api_bp)

# secret key for sessions; in production set through env or config file
app.secret_key = os.environ.get('GOST_PANEL_SECRET') or hashlib.sha256(b'gost-panel-secret').hexdigest()

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    
    # Users/Rules table
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (id INTEGER PRIMARY KEY AUTOINCREMENT, 
                  name TEXT, 
                  protocol TEXT, 
                  listen TEXT, 
                  target TEXT, 
                  password TEXT, 
                  extra TEXT,
                  chain_nodes TEXT)''')
    
    # Nodes table for multi-hop chains
    c.execute('''CREATE TABLE IF NOT EXISTS nodes
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT UNIQUE NOT NULL,
                  forward TEXT NOT NULL,
                  description TEXT)''')
    
    # Admins table
    c.execute('''CREATE TABLE IF NOT EXISTS admins
                 (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password_hash TEXT)''')
    
    # create default admin if not exists
    c.execute("SELECT COUNT(*) FROM admins")
    if c.fetchone()[0] == 0:
        # default admin: admin / admin (change after install)
        default_pw = hashlib.sha256(b'admin').hexdigest()
        c.execute("INSERT INTO admins(username,password_hash) VALUES (?,?)", ("admin", default_pw))
    
    # Try to add chain_nodes column to existing users table (migration)
    try:
        c.execute("ALTER TABLE users ADD COLUMN chain_nodes TEXT")
    except sqlite3.OperationalError:
        pass  # Column already exists
    
    conn.commit()
    conn.close()

def check_admin():
    if 'admin' not in session:
        return False
    return True

def verify_admin(user, pw):
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT password_hash FROM admins WHERE username=?",(user,))
    row = c.fetchone()
    conn.close()
    if not row: return False
    return hashlib.sha256(pw.encode()).hexdigest() == row[0]

def restart_gost_service():
    """
    Mock function for local development
    In production (VPS), this would call: systemctl restart gost
    """
    print("\n" + "="*60)
    print("🔄 [LOCAL MODE] Simulando restart do serviço GOST...")
    print(f"📄 Configuração salva em: {CONF}")
    print("="*60 + "\n")
    return True

@app.route('/login', methods=['GET','POST'])
def login():
    if request.method=='POST':
        user = request.form['username']
        pw = request.form['password']
        if verify_admin(user,pw):
            session['admin']=user
            return redirect(url_for('index'))
        else:
            flash('Credenciais inválidas')
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('admin', None)
    return redirect(url_for('login'))

@app.route('/')
def index():
    if not check_admin(): return redirect(url_for('login'))
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target FROM users")
    users = c.fetchall()
    conn.close()
    return render_template('index.html', users=users)

@app.route('/users/create', methods=['GET','POST'])
def create_user():
    if not check_admin(): return redirect(url_for('login'))
    if request.method=='POST':
        name = request.form['name']
        protocol = request.form['protocol']
        listen = request.form['listen']
        target = request.form['target']
        password = request.form.get('password','')
        extra = request.form.get('extra','')
        conn = sqlite3.connect(DB)
        c = conn.cursor()
        c.execute("INSERT INTO users(name,protocol,listen,target,password,extra,chain_nodes) VALUES (?,?,?,?,?,?,?)",
                  (name,protocol,listen,target,password,extra,chain_nodes))
        conn.commit()
        conn.close()
        flash('Regra criada')
        return redirect(url_for('index'))
    return render_template('create_user.html')

@app.route('/users/<int:uid>/edit', methods=['GET','POST'])
def edit_user(uid):
    if not check_admin(): return redirect(url_for('login'))
    
    if request.method=='POST':
        name = request.form['name']
        protocol = request.form['protocol']
        listen = request.form['listen']
        target = request.form['target']
        password = request.form.get('password','')
        extra = request.form.get('extra','')
        conn = sqlite3.connect(DB)
        c = conn.cursor()
        c.execute("""UPDATE users SET name=?, protocol=?, listen=?, target=?, password=?, extra=?, chain_nodes=?
                     WHERE id=?""",
                  (name,protocol,listen,target,password,extra,chain_nodes,uid))
        conn.commit()
        conn.close()
        flash('Regra atualizada com sucesso')
        return redirect(url_for('index'))
    
    # GET: carregar dados atuais
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target,password,extra FROM users WHERE id=?",(uid,))
    row = c.fetchone()
    conn.close()
    if not row: 
        flash('Regra não encontrada')
        return redirect(url_for('index'))
    user = {
        'id': row[0],
        'name': row[1],
        'protocol': row[2],
        'listen': row[3],
        'target': row[4],
        'password': row[5],
        'extra': row[6],
        'chain_nodes': row[7] if len(row) > 7 else ''
    }
    return render_template('edit_user.html', user=user)

@app.route('/users/<int:uid>/qr')
def user_qr(uid):
    if not check_admin(): return redirect(url_for('login'))
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target,password,extra FROM users WHERE id=?",(uid,))
    row = c.fetchone()
    conn.close()
    if not row: return "Not found", 404
    # build URI depending on protocol
    name = row[1]; protocol = row[2]; listen = row[3]; target = row[4]; password=row[5]; extra=row[6]
    host = request.host.split(':')[0]
    port = "PORT"
    try:
        port = listen.split(':')[-1]
    except:
        pass

    uri = ""
    if protocol.lower().startswith("socks"):
        uri = f"socks5://{host}:{port}"
    elif protocol.lower().startswith("ss"):
        # supports ss://method:password@host:port  -> encode as base64 for common mobile apps
        method = extra.split(',')[0] if extra else 'aes-256-gcm'
        pwd = password or 'pass'
        payload = f"{method}:{pwd}@{host}:{port}"
        b64 = base64.urlsafe_b64encode(payload.encode()).decode().strip('=')
        uri = f"ss://{b64}"
    elif protocol.lower().startswith("vmess"):
        # create basic vmess JSON and base64 encode
        vm = {
            "v": "2",
            "ps": name,
            "add": host,
            "port": int(port) if port.isdigit() else 0,
            "id": extra or secrets.token_hex(16),
            "aid":"0",
            "net":"tcp",
            "type":"none",
            "host":"",
            "path":"",
            "tls":""
        }
        vm_b64 = base64.b64encode(json.dumps(vm).encode()).decode().strip('=')
        uri = f"vmess://{vm_b64}"
    elif protocol.lower().startswith("vless"):
        # vless simple: vless://UUID@host:port
        uuid = extra or secrets.token_hex(16)
        uri = f"vless://{uuid}@{host}:{port}"
    else:
        uri = f"{protocol}://{host}:{port}"

    img = qrcode.make(uri)
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    buf.seek(0)
    return send_file(buf, mimetype='image/png')

@app.route('/apply', methods=['POST'])
def apply_config():
    if not check_admin(): return redirect(url_for('login'))
    # Build a gost config from DB users plus some advanced sections
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target,password,extra,chain_nodes FROM users")
    rows = c.fetchall()
    
    # Get all nodes for chains
    c.execute("SELECT name,forward FROM nodes")
    node_rows = c.fetchall()
    conn.close()
    
    servers = []
    nodes_config = []
    
    # Build nodes section
    for node_name, node_forward in node_rows:
        nodes_config.append({
            "name": node_name,
            "addr": node_forward
        })
    
    # Build servers section
    for r in rows:
        rule_id, name, protocol, listen, target, password, extra, chain_nodes = r
        s = {
            "name": name,
            "addr": listen
        }
        
        # Handle chain multi-hop
        if chain_nodes and chain_nodes.strip():
            # Chain format: chain://node1,node2,node3
            s["handler"] = {
                "type": protocol,
                "chain": chain_nodes.strip()
            }
            s["listener"] = {
                "type": protocol
            }
        else:
            # Direct forward (no chain)
            # Check if target has multiple addresses (load balancing)
            if ',' in target:
                targets = [t.strip() for t in target.split(',')]
                s["forwarder"] = {
                    "nodes": [{"addr": t} for t in targets],
                    "selector": {
                        "strategy": extra.split('strategy=')[-1].split(',')[0] if 'strategy=' in (extra or '') else "round",
                        "maxFails": 3,
                        "failTimeout": 30
                    }
                }
            else:
                s["forwarder"] = {
                    "nodes": [{"addr": target}]
                }
        
        # attach simple rate limit if extra contains rl=<kbps>
        if extra and 'rl=' in extra:
            try:
                rl = int(extra.split('rl=')[-1].split(',')[0])
                if 'handler' not in s:
                    s['handler'] = {}
                s['handler']['limiter'] = {"rate": f"{rl}KB"}
            except:
                pass
        
        servers.append(s)
    
    cfg = {
        "services": servers,
        "chains": nodes_config if nodes_config else []
    }
    
    # Add metrics
    cfg["api"] = {
        "addr": "127.0.0.1:18080",
        "pathPrefix": "/api"
    }
    
    os.makedirs(os.path.dirname(CONF), exist_ok=True)
    with open(CONF, "w") as f:
        json.dump(cfg, f, indent=2)
    
    # Use mock restart for local development
    restart_gost_service()
    
    flash('Config aplicada e gost reiniciado (modo local - simulado).')
    return redirect(url_for('index'))


# ============================================================
# Node Management Routes (for Chain Multi-Hop)
# ============================================================

@app.route('/nodes')
def list_nodes():
    if not check_admin(): return redirect(url_for('login'))
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id,name,forward,description FROM nodes ORDER BY name")
    nodes = c.fetchall()
    conn.close()
    return render_template('nodes.html', nodes=nodes)

@app.route('/nodes/create', methods=['GET','POST'])
def create_node():
    if not check_admin(): return redirect(url_for('login'))
    if request.method=='POST':
        name = request.form['name']
        forward = request.form['forward']
        description = request.form.get('description','')
        conn = sqlite3.connect(DB)
        c = conn.cursor()
        try:
            c.execute("INSERT INTO nodes(name,forward,description) VALUES (?,?,?)",
                      (name,forward,description))
            conn.commit()
            flash(f'Node "{name}" criado com sucesso')
        except sqlite3.IntegrityError:
            flash(f'Erro: Já existe um node com o nome "{name}"')
        conn.close()
        return redirect(url_for('list_nodes'))
    return render_template('create_node.html')

@app.route('/nodes/<int:nid>/delete', methods=['POST'])
def delete_node(nid):
    if not check_admin(): return redirect(url_for('login'))
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("DELETE FROM nodes WHERE id=?",(nid,))
    conn.commit()
    conn.close()
    flash('Node removido')
    return redirect(url_for('list_nodes'))

# ============================================================
# Dynamic Reload Route
# ============================================================

@app.route('/reload', methods=['POST'])
def reload_config():
    if not check_admin(): return redirect(url_for('login'))
    try:
        # Validate config exists and is valid JSON
        with open(CONF, 'r') as f:
            json.load(f)
        # In production, send SIGHUP or use GOST API
        print("\n" + "="*60)
        print("🔄 [RELOAD] Configuração recarregada sem restart")
        print("="*60 + "\n")
        flash('Configuração recarregada com sucesso (modo local - simulado)')
    except FileNotFoundError:
        flash('Erro: Arquivo de configuração não encontrado. Aplique a configuração primeiro.')
    except json.JSONDecodeError:
        flash('Erro: Arquivo de configuração inválido')
    return redirect(url_for('index'))


@app.route('/users/<int:uid>/delete', methods=['POST'])
def delete_user(uid):
    if not check_admin(): return redirect(url_for('login'))
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("DELETE FROM users WHERE id=?",(uid,))
    conn.commit()
    conn.close()
    flash('Regra removida')
    return redirect(url_for('index'))

if __name__ == '__main__':
    print("\n" + "="*60)
    print("🚀 GOST Panel - Modo de Desenvolvimento Local")
    print("="*60)
    print(f"📂 Diretório de dados: {LOCAL_DATA_DIR}")
    print(f"📂 Diretório de config: {LOCAL_CONFIG_DIR}")
    print(f"🗄️  Banco de dados: {DB}")
    print(f"⚙️  Arquivo de config: {CONF}")
    print("="*60)
    print("🔐 Credenciais padrão: admin / admin")
    print("🌐 Acesse: http://localhost:5000")
    print("="*60 + "\n")
    
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
