# TProxy helper script (BASIC - test before using in production)
# Usage: sudo bash tproxy_setup.sh <local_port> <mark>
# This script requires iptables with TPROXY support and Linux kernel configured for TPROXY.
# It creates rules to redirect traffic to a local transparent proxy listening on <local_port>.

IPTABLES=/sbin/iptables
NF_LOG=/sbin/nft

echo "Enable forwarding and rp_filter settings..."
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0

LOCAL_PORT=${1:-1080}
MARK=${2:-0x1}

echo "Create mangle table rules for TPROXY..."
iptables -t mangle -N GOST_TPROXY 2>/dev/null || true
iptables -t mangle -F GOST_TPROXY || true
iptables -t mangle -A PREROUTING -p tcp -m socket -j RETURN || true
iptables -t mangle -A PREROUTING -p tcp -j TPROXY --on-port ${LOCAL_PORT} --tproxy-mark ${MARK} || true

echo "Done. Note: you must run a transparent proxy listening on ${LOCAL_PORT} and handle restored sockets."
