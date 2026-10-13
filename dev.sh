#!/usr/bin/env bash
VENV_PY=/home/odoo20/odoo20/venv/bin/python3
ODOO_BIN=/home/odoo20/odoo20/odoo/odoo-bin
CONF=/home/odoo20/odoo20/odoo.conf
cd /home/odoo20/odoo20/odoo
exec "$VENV_PY" "$ODOO_BIN" -c "$CONF" -d odoo20 --dev=reload,qweb,xml "$@"
