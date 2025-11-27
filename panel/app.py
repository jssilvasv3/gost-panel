#!/usr/bin/env python3
"""
GOST Panel - Production Version for VPS
Includes all advanced features: Edit, API, Chains, Load Balancing, Reload
"""
import os, sqlite3, json, subprocess, qrcode, io, base64, secrets, hashlib, uuid
from flask import Flask, render_template, request, redirect, url_for, send_file, flash, session, abort
from routes.protocols import protocols_bp
from routes.api import api_bp

# Production paths (VPS)
APP_DIR = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(APP_DIR, "panel.db")
CONF = os.path.join("/etc/gost", "config.json")
CFG_PANEL = os.path.join(APP_DIR, "panel.conf.json")

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
    Restart GOST service in production (VPS)
    """
    try:
        subprocess.run(["systemctl", "restart", "gost"], check=True)
        return True
    except Exception as e:
        print(f"Error restarting GOST: {e}")
        return False

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

@app.route('/status')
def get_status():
    """Get system status for dashboard"""
    import psutil
    
    status = {
        'panel': 'online',
        'gost_service': 'unknown',
        'gost_pid': None,
        'active_tunnels': 0,
        'total_rules': 0,
        'listening_ports': []
    }
    
    try:
        # Check GOST service status
        result = subprocess.run(['systemctl', 'is-active', 'gost'], 
                              capture_output=True, text=True, timeout=2)
        status['gost_service'] = 'running' if result.stdout.strip() == 'active' else 'stopped'
    except:
        status['gost_service'] = 'unknown'
    
    try:
        # Get GOST PID
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            if 'gost' in proc.info['name'].lower():
                status['gost_pid'] = proc.info['pid']
                break
    except:
        pass
    
    try:
        # 1. Get expected ports from DB
        conn = sqlite3.connect(DB)
        c = conn.cursor()
        c.execute("SELECT listen FROM users")
        expected_ports = set()
        rows = c.fetchall()
        status['total_rules'] = len(rows)
        for row in rows:
            # listen string is like ":8080" or "0.0.0.0:8080"
            if ':' in row[0]:
                port = row[0].split(':')[-1]
                if port.isdigit():
                    expected_ports.add(port)
        conn.close()

        # 2. Get actual listening ports (TCP + UDP)
        # ss -tlnu (no -p to avoid permission issues)
        result = subprocess.run(['ss', '-tlnu'], capture_output=True, text=True, timeout=2)
        active_ports = set()
        
        for line in result.stdout.split('\n'):
            parts = line.split()
            # Output format: Netid State Recv-Q Send-Q Local_Address:Port Peer_Address:Port
            # Example: tcp LISTEN 0 4096 *:8080 *:*
            if len(parts) >= 5 and (parts[0] in ['tcp', 'udp']):
                addr = parts[4]
                if ':' in addr:
                    port = addr.split(':')[-1]
                    if port.isdigit():
                        active_ports.add(port)
        
        # 3. Calculate intersection (Active Tunnels)
        matching_ports = expected_ports.intersection(active_ports)
        status['active_tunnels'] = len(matching_ports)
        status['listening_ports'] = sorted(list(matching_ports))
        
    except Exception as e:
        print(f"Error getting status: {e}")
        status['active_tunnels'] = 0
    
    from flask import jsonify
    return jsonify(status)

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
        protocol = request.form['protocol'].lower()
        
        # Initialize with defaults
        name = ''
        listen = ''
        target = 'tcp://0.0.0.0:0'
        password = ''
        extra = ''
        chain_nodes = ''
        
        # Auto-generate everything based on protocol
        protocol_config = {
            # Protocolos Criptografados (Xray)
            'ss': {'port': ':8389', 'password': secrets.token_urlsafe(16), 'extra': 'method=aes-256-gcm'},
            'vmess': {'port': ':10086', 'extra': f'uuid={str(uuid.uuid4())},alterId=0'},
            'vless': {'port': ':10087', 'extra': f'uuid={str(uuid.uuid4())}'},
            'trojan': {'port': ':8443', 'password': secrets.token_urlsafe(16)},
            
            # Proxies Básicos
            'socks5': {'port': ':1081'},
            'socks4': {'port': ':1080'},
            'http': {'port': ':8080'},
            'https': {'port': ':8443'},
            
            # Protocolos Avançados (GOST)
            'ws': {'port': ':8081'},
            'wss': {'port': ':8082'},
            'http2': {'port': ':8083'},
            'h2': {'port': ':8084'},
            'h2c': {'port': ':8085'},
            'grpc': {'port': ':8086'},
            'quic': {'port': ':8087'},
            'kcp': {'port': ':8088'},
            'ssh': {'port': ':2222'},
            'sshd': {'port': ':2223'},
            
            # Túneis Especiais
            'tcp': {'port': ':9000'},
            'udp': {'port': ':9001'},
            'rtcp': {'port': ':9002'},
            'rudp': {'port': ':9003'},
            'tls': {'port': ':9004'},
            'dtls': {'port': ':9005'},
            'icmp': {'port': ':9006'},
            
            # DNS & Redes
            'dns': {'port': ':53'},
            'doh': {'port': ':8053'},
            'dot': {'port': ':853'},
            'relay': {'port': ':9100'},
            'forward': {'port': ':9101'},
        }
        
        # Get config for protocol or use default
        config = protocol_config.get(protocol, {'port': ':10000'})
        
        listen = config.get('port', ':10000')
        password = config.get('password', '')
        extra = config.get('extra', '')
        name = f'{protocol.upper()}-{listen.strip(":")}'
        
        conn = sqlite3.connect(DB)
        c = conn.cursor()
        c.execute("INSERT INTO users(name,protocol,listen,target,password,extra,chain_nodes) VALUES (?,?,?,?,?,?,?)",
                  (name,protocol,listen,target,password,extra,chain_nodes))
        conn.commit()
        conn.close()
        flash(f'✅ Regra "{name}" criada! Configuração gerada automaticamente.')
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
        chain_nodes = request.form.get('chain_nodes', '')
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
    c.execute("SELECT id,name,protocol,listen,target,password,extra,chain_nodes FROM users WHERE id=?",(uid,))
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
    host = "138.197.212.221"  # Public IP of VPS
    port = "PORT"
    try:
        port = listen.split(':')[-1]
    except:
        pass

    uri = ""
    if protocol.lower().startswith("socks"):
        uri = f"socks5://{host}:{port}"
    elif protocol.lower().startswith("ss"):
        # supports ss://method:password@host:port -> encode as base64 for common mobile apps
        method = 'aes-256-gcm'
        if extra and 'method=' in extra:
            method = extra.split('method=')[1].split(',')[0]
        pwd = password or 'pass'
        payload = f"{method}:{pwd}@{host}:{port}"
        b64 = base64.urlsafe_b64encode(payload.encode()).decode().strip('=')
        uri = f"ss://{b64}"
    elif protocol.lower().startswith("vmess"):
        # create basic vmess JSON and base64 encode
        # Extract UUID from extra field
        vmess_uuid = secrets.token_hex(16)
        if extra and 'uuid=' in extra:
            vmess_uuid = extra.split('uuid=')[1].split(',')[0]
        
        vm = {
            "v": "2",
            "ps": name,
            "add": host,
            "port": int(port) if port.isdigit() else 0,
            "id": vmess_uuid,
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
        vless_uuid = secrets.token_hex(16)
        if extra and 'uuid=' in extra:
            vless_uuid = extra.split('uuid=')[1].split(',')[0]
        uri = f"vless://{vless_uuid}@{host}:{port}"
    elif protocol.lower().startswith("trojan"):
        # trojan://password@host:port?sni=host&type=tcp&security=tls#name
        trojan_pwd = password or 'default_password'
        # Trojan precisa de SNI e security
        uri = f"trojan://{trojan_pwd}@{host}:{port}?security=none&type=tcp#{name}"
    else:
        uri = f"{protocol}://{host}:{port}"

    img = qrcode.make(uri)
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    buf.seek(0)
    return send_file(buf, mimetype='image/png')

def generate_gost_config(rules):
    """Generate GOST v3 configuration from rules with chain and load balancing support"""
    services = []
    
    # Get nodes from database for chains
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT name, forward FROM nodes")
    node_rows = c.fetchall()
    conn.close()
    
    # Build nodes config
    nodes_config = []
    for node_name, node_forward in node_rows:
        nodes_config.append({
            "name": node_name,
            "addr": node_forward
        })
    
    for rule in rules:
        rule_id, name, protocol, listen, target, password, extra, chain_nodes = rule
        
        # Extract port from listen
        port = listen if listen.startswith(':') else f":{listen.split(':')[-1]}"
        
        service = {
            "name": name or f"{protocol}-{rule_id}",
            "addr": port,
            "handler": {
                "type": protocol
            },
            "listener": {
                "type": "tcp"
            }
        }
        
        # Add authentication if needed
        if password and protocol in ['socks5', 'http', 'https']:
            service["handler"]["auth"] = {
                "username": "",
                "password": password
            }
        
        # Handle chain multi-hop
        if chain_nodes and chain_nodes.strip():
            service["handler"]["chain"] = chain_nodes.strip()
        else:
        
            # Handle load balancing (multiple targets)
            if target and ',' in target:
                targets = [t.strip() for t in target.split(',')]
                service["forwarder"] = {
                    "nodes": [{"addr": t} for t in targets],
                    "selector": {
                        "strategy": extra.split('strategy=')[-1].split(',')[0] if extra and 'strategy=' in extra else "round",
                        "maxFails": 3,
                        "failTimeout": 30
                    }
                }
            elif target and target != 'tcp://0.0.0.0:0':
                # Single target
                service["forwarder"] = {
                    "nodes": [{"addr": target}]
                }
        
        # Handle specific protocols
        if protocol in ['socks5', 'socks4', 'http', 'tcp', 'udp', 'rtcp', 'rudp', 'relay', 'forward']:
            service['handler']['type'] = protocol
            if protocol in ['udp', 'rudp']:
                service['listener']['type'] = 'udp'
            elif protocol in ['rtcp']:
                service['listener']['type'] = 'tcp'
        
        # Advanced protocols with TLS
        elif protocol in ['wss', 'http2', 'h2', 'h2c', 'grpc', 'quic', 'kcp', 'tls', 'dtls']:
            service['handler']['type'] = 'socks5' # Default handler for tunnels
            service['listener']['type'] = protocol
            
            # Add TLS config for secure protocols
            if protocol in ['wss', 'h2', 'quic', 'tls', 'dtls']:
                service['listener']['tls'] = {
                    "certFile": "/etc/gost/certs/server.crt",
                    "keyFile": "/etc/gost/certs/server.key"
                }
            
            # Special listeners
            if protocol in ['quic', 'kcp', 'dtls']:
                # These use UDP listener under the hood in GOST v2, but config is type=protocol
                pass 
                
        # Chain handling
        if chain_nodes:
            service['chain'] = f"chain-{rule_id}"
            
        # Load balancing
        if target and ',' in target:
            # Simple load balancing
            pass
            
        services.append(service)
    
    return {
        "services": services,
        "chains": nodes_config if nodes_config else [],
        "api": {
            "addr": "127.0.0.1:18080",
            "pathPrefix": "/api"
        }
    }


def generate_shadowsocks_config(rules):
    """Generate Shadowsocks-libev configuration from rules (first rule only)"""
    if not rules:
        return None
    
    # Use first SS rule
    rule = rules[0]
    rule_id, name, protocol, listen, target, password, extra, chain_nodes = rule
    
    # Extract port
    port = int(listen.split(':')[-1]) if ':' in listen else 8389
    
    # Extract method from extra
    method = "aes-256-gcm"
    if extra and 'method=' in extra:
        method = extra.split('method=')[1].split(',')[0]
    
    return {
        "server": "0.0.0.0",
        "server_port": port,
        "password": password or "default_password",
        "timeout": 300,
        "method": method,
        "mode": "tcp_and_udp"
    }

def generate_xray_config(rules):
    """Generate Xray configuration from rules"""
    inbounds = []
    
    for rule in rules:
        rule_id, name, protocol, listen, target, password, extra, chain_nodes = rule
        
        # Extract port
        port = int(listen.split(':')[-1]) if ':' in listen else 10086
        
        inbound = {
            "port": port,
            "protocol": protocol,
            "tag": name or f"{protocol}-{rule_id}"
        }
        
        if protocol == "vmess":
            # Extract or generate UUID
            uid = str(uuid.uuid4())
            if extra and 'uuid=' in extra:
                uid = extra.split('uuid=')[1].split(',')[0]
            
            inbound["settings"] = {
                "clients": [{
                    "id": uid,
                    "alterId": 0
                }]
            }
            inbound["streamSettings"] = {"network": "tcp"}
            
        elif protocol == "vless":
            # Extract or generate UUID
            uid = str(uuid.uuid4())
            if extra and 'uuid=' in extra:
                uid = extra.split('uuid=')[1].split(',')[0]
            
            inbound["settings"] = {
                "clients": [{
                    "id": uid,
                    "flow": ""
                }],
                "decryption": "none"
            }
            inbound["streamSettings"] = {"network": "tcp"}
            
        elif protocol == "trojan":
            inbound["settings"] = {
                "clients": [{
                    "password": password or "default_password"
                }]
            }
            inbound["streamSettings"] = {"network": "tcp"}
        
        inbounds.append(inbound)
    
    return {
        "log": {"loglevel": "warning"},
        "inbounds": inbounds,
        "outbounds": [{"protocol": "freedom"}]
    }

@app.route('/apply', methods=['POST'])


def apply_config():
    if not check_admin(): return redirect(url_for('login'))
    
    # Fetch all rules from database
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target,password,extra,chain_nodes FROM users")
    all_rules = c.fetchall()
    conn.close()
    
    # Group rules by service type
    # Group rules by service type
    gost_protocols = [
        'socks5', 'socks4', 'http', 'https', 'tcp', 'udp',
        'wss', 'http2', 'h2', 'h2c', 'grpc', 'quic', 'kcp',
        'rtcp', 'rudp', 'tls', 'dtls', 'relay', 'forward'
    ]
    ss_protocols = ['ss']
    xray_protocols = ['vmess', 'vless', 'trojan']
    
    gost_rules = [r for r in all_rules if r[2].lower() in gost_protocols]
    ss_rules = [r for r in all_rules if r[2].lower() in ss_protocols]
    xray_rules = [r for r in all_rules if r[2].lower() in xray_protocols]
    
    services_restarted = []
    
    try:
        # Generate and write GOST config
        if gost_rules:
            gost_config = generate_gost_config(gost_rules)
            os.makedirs(os.path.dirname(CONF), exist_ok=True)
            with open(CONF, 'w') as f:
                json.dump(gost_config, f, indent=2)
            
            # Restart GOST
            subprocess.run(['sudo', 'systemctl', 'restart', 'gost'], check=False)
            services_restarted.append('GOST')
        
        # Generate and write Shadowsocks config
        if ss_rules:
            ss_config = generate_shadowsocks_config(ss_rules)
            if ss_config:
                os.makedirs('/etc/shadowsocks-libev', exist_ok=True)
                with open('/etc/shadowsocks-libev/config.json', 'w') as f:
                    json.dump(ss_config, f, indent=2)
                
                # Restart Shadowsocks
                subprocess.run(['sudo', 'systemctl', 'restart', 'shadowsocks-libev-server@config'], check=False)
                services_restarted.append('Shadowsocks')
        
        # Generate and write Xray config
        if xray_rules:
            xray_config = generate_xray_config(xray_rules)
            os.makedirs('/usr/local/etc/xray', exist_ok=True)
            with open('/usr/local/etc/xray/config.json', 'w') as f:
                json.dump(xray_config, f, indent=2)
            
            # Restart Xray
            subprocess.run(['sudo', 'systemctl', 'restart', 'xray'], check=False)
            services_restarted.append('Xray')
        
        if services_restarted:
            flash(f'✅ Configuração aplicada! Serviços reiniciados: {", ".join(services_restarted)}')
        else:
            flash('⚠️ Nenhuma regra encontrada. Nenhum serviço foi configurado.')
            
    except Exception as e:
        flash(f'❌ Erro ao aplicar configuração: {str(e)}')
    
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
        # Send SIGHUP to GOST process
        subprocess.run(["killall", "-HUP", "gost"], check=False)
        flash('Configuração recarregada com sucesso')
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

@app.route('/debug/config')
def debug_config():
    if not check_admin(): return redirect(url_for('login'))
    
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target,password,extra,chain_nodes FROM users")
    all_rules = c.fetchall()
    conn.close()
    
    gost_protocols = [
        'socks5', 'socks4', 'http', 'https', 'tcp', 'udp',
        'wss', 'http2', 'h2', 'h2c', 'grpc', 'quic', 'kcp',
        'rtcp', 'rudp', 'tls', 'dtls', 'relay', 'forward'
    ]
    
    gost_rules = [r for r in all_rules if r[2].lower() in gost_protocols]
    config = generate_gost_config(gost_rules)
    
    return jsonify({
        "gost_protocols": gost_protocols,
        "total_rules": len(all_rules),
        "gost_rules_count": len(gost_rules),
        "config": config
    })

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=False)
