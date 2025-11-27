from flask import Blueprint, render_template, jsonify, request

protocols_bp = Blueprint("protocols", __name__)

protocol_list = [
    {"name": "SOCKS5", "desc": "Proxy TCP/UDP completo", "mobile": "Android/iOS", "qr": True, "status": True},
    {"name": "SOCKS4/4A", "desc": "Proxy TCP simples", "mobile": "Android", "qr": False, "status": True},
    {"name": "HTTP Proxy", "desc": "Proxy HTTP tradicional", "mobile": "Android/iOS", "qr": False, "status": True},
    {"name": "HTTPS Proxy", "desc": "CONNECT com TLS", "mobile": "Android/iOS", "qr": False, "status": True},
    {"name": "REDIR TCP", "desc": "Proxy transparente TCP", "mobile": "Android (root)", "qr": False, "status": False},
    {"name": "TPROXY UDP", "desc": "Proxy transparente UDP", "mobile": "Android (root)", "qr": False, "status": False},
    {"name": "Tunnel TCP", "desc": "Tunnel binário via TLS/HTTP2/QUIC", "mobile": "Android/iOS", "qr": False, "status": True},
    {"name": "QUIC Tunnel", "desc": "Tunelamento QUIC", "mobile": "Android/iOS", "qr": False, "status": False},
    {"name": "Relay", "desc": "Encaminhamento TCP/UDP", "mobile": "Android/iOS", "qr": False, "status": True},
    {"name": "Chain Multi-Hop", "desc": "Encadeamento multinível", "mobile": "Android/iOS", "qr": False, "status": True},
    {"name": "TUN2SOCKS", "desc": "VPN L3 → L4", "mobile": "Android/iOS", "qr": False, "status": True},
    {"name": "DNS Proxy", "desc": "Resolver DNS local", "mobile": "Android/iOS", "qr": False, "status": True},
]

@protocols_bp.route("/protocols")
def protocols_page():
    return render_template("protocols.html", protocols=protocol_list)

@protocols_bp.route("/protocols/toggle", methods=["POST"])
def toggle_protocol():
    name = request.json.get("name")

    for p in protocol_list:
        if p["name"] == name:
            p["status"] = not p["status"]
            return jsonify({"success": True, "status": p["status"]})

    return jsonify({"success": False}), 404
