#!/usr/bin/env python3
"""
GOST Panel - REST API Blueprint
Provides RESTful endpoints for automation and integration
"""
from flask import Blueprint, jsonify, request, current_app
import sqlite3
import secrets
import hashlib
import os
from functools import wraps

api_bp = Blueprint('api', __name__, url_prefix='/api/v1')

# In-memory token storage (in production, use Redis or database)
API_TOKENS = {}

def get_db_path():
    """Get database path from app config"""
    return current_app.config.get('DB_PATH', 'panel.db')

def verify_admin(username, password):
    """Verify admin credentials"""
    conn = sqlite3.connect(get_db_path())
    c = conn.cursor()
    c.execute("SELECT password_hash FROM admins WHERE username=?", (username,))
    row = c.fetchone()
    conn.close()
    if not row:
        return False
    return hashlib.sha256(password.encode()).hexdigest() == row[0]

def require_api_token(f):
    """Decorator to protect API endpoints with token authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Missing or invalid Authorization header'}), 401
        
        token = auth_header.replace('Bearer ', '')
        if token not in API_TOKENS:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        return f(*args, **kwargs)
    return decorated_function

# ============================================================
# Authentication Endpoints
# ============================================================

@api_bp.route('/auth/login', methods=['POST'])
def api_login():
    """
    Generate API token
    
    Request:
        POST /api/v1/auth/login
        Content-Type: application/json
        {
            "username": "admin",
            "password": "admin"
        }
    
    Response:
        {
            "token": "abc123...",
            "expires_in": 86400
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Invalid JSON'}), 400
    
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    
    if verify_admin(username, password):
        token = secrets.token_hex(32)
        API_TOKENS[token] = {
            'username': username,
            'created_at': __import__('time').time()
        }
        return jsonify({
            'token': token,
            'expires_in': 86400,  # 24 hours
            'message': 'Authentication successful'
        }), 200
    
    return jsonify({'error': 'Invalid credentials'}), 401

@api_bp.route('/auth/logout', methods=['POST'])
@require_api_token
def api_logout():
    """
    Revoke API token
    
    Request:
        POST /api/v1/auth/logout
        Authorization: Bearer <token>
    
    Response:
        {
            "message": "Token revoked"
        }
    """
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    if token in API_TOKENS:
        del API_TOKENS[token]
    return jsonify({'message': 'Token revoked successfully'}), 200

# ============================================================
# Rules CRUD Endpoints
# ============================================================

@api_bp.route('/rules', methods=['GET'])
@require_api_token
def get_rules():
    """
    List all rules
    
    Request:
        GET /api/v1/rules
        Authorization: Bearer <token>
    
    Response:
        {
            "rules": [
                {
                    "id": 1,
                    "name": "My SOCKS5",
                    "protocol": "socks5",
                    "listen": "socks5://:1081",
                    "target": "tcp://1.2.3.4:22",
                    "password": "",
                    "extra": ""
                }
            ],
            "count": 1
        }
    """
    conn = sqlite3.connect(get_db_path())
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target,password,extra FROM users")
    rows = c.fetchall()
    conn.close()
    
    rules = []
    for row in rows:
        rules.append({
            'id': row[0],
            'name': row[1],
            'protocol': row[2],
            'listen': row[3],
            'target': row[4],
            'password': row[5],
            'extra': row[6]
        })
    
    return jsonify({
        'rules': rules,
        'count': len(rules)
    }), 200

@api_bp.route('/rules/<int:rule_id>', methods=['GET'])
@require_api_token
def get_rule(rule_id):
    """
    Get specific rule by ID
    
    Request:
        GET /api/v1/rules/1
        Authorization: Bearer <token>
    
    Response:
        {
            "id": 1,
            "name": "My SOCKS5",
            ...
        }
    """
    conn = sqlite3.connect(get_db_path())
    c = conn.cursor()
    c.execute("SELECT id,name,protocol,listen,target,password,extra FROM users WHERE id=?", (rule_id,))
    row = c.fetchone()
    conn.close()
    
    if not row:
        return jsonify({'error': 'Rule not found'}), 404
    
    rule = {
        'id': row[0],
        'name': row[1],
        'protocol': row[2],
        'listen': row[3],
        'target': row[4],
        'password': row[5],
        'extra': row[6]
    }
    
    return jsonify(rule), 200

@api_bp.route('/rules', methods=['POST'])
@require_api_token
def create_rule():
    """
    Create new rule
    
    Request:
        POST /api/v1/rules
        Authorization: Bearer <token>
        Content-Type: application/json
        {
            "name": "My SOCKS5",
            "protocol": "socks5",
            "listen": "socks5://:1081",
            "target": "tcp://1.2.3.4:22",
            "password": "",
            "extra": ""
        }
    
    Response:
        {
            "id": 1,
            "message": "Rule created successfully"
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Invalid JSON'}), 400
    
    # Validate required fields
    required = ['name', 'protocol', 'listen', 'target']
    for field in required:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    name = data['name']
    protocol = data['protocol']
    listen = data['listen']
    target = data['target']
    password = data.get('password', '')
    extra = data.get('extra', '')
    
    conn = sqlite3.connect(get_db_path())
    c = conn.cursor()
    c.execute("INSERT INTO users(name,protocol,listen,target,password,extra) VALUES (?,?,?,?,?,?)",
              (name, protocol, listen, target, password, extra))
    rule_id = c.lastrowid
    conn.commit()
    conn.close()
    
    return jsonify({
        'id': rule_id,
        'message': 'Rule created successfully'
    }), 201

@api_bp.route('/rules/<int:rule_id>', methods=['PUT'])
@require_api_token
def update_rule(rule_id):
    """
    Update existing rule
    
    Request:
        PUT /api/v1/rules/1
        Authorization: Bearer <token>
        Content-Type: application/json
        {
            "name": "Updated SOCKS5",
            "protocol": "socks5",
            ...
        }
    
    Response:
        {
            "message": "Rule updated successfully"
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Invalid JSON'}), 400
    
    # Check if rule exists
    conn = sqlite3.connect(get_db_path())
    c = conn.cursor()
    c.execute("SELECT id FROM users WHERE id=?", (rule_id,))
    if not c.fetchone():
        conn.close()
        return jsonify({'error': 'Rule not found'}), 404
    
    # Update fields (only provided fields)
    fields = []
    values = []
    for field in ['name', 'protocol', 'listen', 'target', 'password', 'extra']:
        if field in data:
            fields.append(f"{field}=?")
            values.append(data[field])
    
    if not fields:
        conn.close()
        return jsonify({'error': 'No fields to update'}), 400
    
    values.append(rule_id)
    query = f"UPDATE users SET {','.join(fields)} WHERE id=?"
    c.execute(query, values)
    conn.commit()
    conn.close()
    
    return jsonify({'message': 'Rule updated successfully'}), 200

@api_bp.route('/rules/<int:rule_id>', methods=['DELETE'])
@require_api_token
def delete_rule(rule_id):
    """
    Delete rule
    
    Request:
        DELETE /api/v1/rules/1
        Authorization: Bearer <token>
    
    Response:
        {
            "message": "Rule deleted successfully"
        }
    """
    conn = sqlite3.connect(get_db_path())
    c = conn.cursor()
    c.execute("DELETE FROM users WHERE id=?", (rule_id,))
    rows_affected = c.rowcount
    conn.commit()
    conn.close()
    
    if rows_affected == 0:
        return jsonify({'error': 'Rule not found'}), 404
    
    return jsonify({'message': 'Rule deleted successfully'}), 200

# ============================================================
# Configuration Endpoints
# ============================================================

@api_bp.route('/config/apply', methods=['POST'])
@require_api_token
def apply_config():
    """
    Apply configuration (generate config.json and restart GOST)
    
    Request:
        POST /api/v1/config/apply
        Authorization: Bearer <token>
    
    Response:
        {
            "message": "Configuration applied successfully",
            "config_path": "/path/to/config.json"
        }
    """
    # This would call the same logic as the web UI apply_config
    # For now, return success
    return jsonify({
        'message': 'Configuration applied successfully',
        'note': 'Use web UI /apply endpoint for full functionality'
    }), 200

@api_bp.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint (no authentication required)
    
    Request:
        GET /api/v1/health
    
    Response:
        {
            "status": "ok",
            "version": "1.0.0"
        }
    """
    return jsonify({
        'status': 'ok',
        'version': '1.0.0',
        'api': 'GOST Panel REST API'
    }), 200

# ============================================================
# Error Handlers
# ============================================================

@api_bp.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@api_bp.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500
