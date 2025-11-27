#!/usr/bin/env bash
# Basic firewall helper (allows panel port 5000 and common proxy ports)
set -euo pipefail
ufw allow 5000/tcp
ufw allow 22/tcp
# proxy ports examples
ufw allow 1080/tcp
ufw allow 2222/tcp
echo "Firewall rules applied (example). Adjust as needed."
