Document: Gost Full Package - Quick Reference
---------------------------------------------
This document provides a short reference to the files included in the package
and steps to deploy on a fresh Ubuntu/Debian server.

1) Unpack:
   unzip gost_full_package.zip -d gost_full_package
   cd gost_full_package

2) Inspect files:
   - install.sh : run as root to install dependencies and configure services
   - panel/ : Flask web panel (edit panel/panel.conf.json to change admin password)
   - examples/ : example gost config templates
   - scripts/ : firewall and tproxy helpers

3) Run installer (example):
   sudo bash install.sh --domain your.domain.tld --email you@domain.tld

4) After installation:
   - Edit /opt/gost-panel/panel.conf.json to change default admin password
   - Access http://your_vps:5000 or https://your.domain.tld
   - Create proxy rules and click "Apply configuration"

5) Safety:
   - Change passwords immediately
   - Run on a test machine before production
   - Understand TProxy effects before enabling transparent proxy

