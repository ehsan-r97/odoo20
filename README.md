# Odoo 20 Full-Stack Installation, Performance, Persian RTL, AI/PostgreSQL, and Addon Development Guide

This repository provides a complete fixed deployment and development environment for **Odoo 20** on **Kubuntu 26 / Ubuntu LTS**.

The setup is intended for:

- Odoo 20 production-style installation.
- Odoo addon development.
- Multiple independent Git-based addon folders.
- High-performance PostgreSQL usage.
- PgBouncer connection pooling.
- Redis cache/session support.
- Nginx reverse proxy with SSL.
- WebSocket and longpolling support.
- Persian `fa_IR` RTL interface support.
- Persian PDF report rendering.
- PostgreSQL AI/vector capabilities using `pgvector`.
- Cloudflare Quick Tunnel for free public HTTPS access.
- Mobile camera testing over HTTPS.
- Fixed configuration values, without parameterized templates.

This guide uses only **English** and **Persian**. Arabic is not included.

---

## Table of Contents

1. [Fixed Deployment Profile](#1-fixed-deployment-profile)
2. [Architecture](#2-architecture)
3. [Prerequisites](#3-prerequisites)
4. [Phase 1: System Preparation](#4-phase-1-system-preparation)
5. [Phase 2: Persian Locale and Font Preparation](#5-phase-2-persian-locale-and-font-preparation)
6. [Phase 3: Operating System Performance Tuning](#6-phase-3-operating-system-performance-tuning)
7. [Phase 4: PostgreSQL 17 Installation and Performance Tuning](#7-phase-4-postgresql-17-installation-and-performance-tuning)
8. [Phase 5: PostgreSQL AI/Vector Extensions](#8-phase-5-postgresql-aivector-extensions)
9. [Phase 6: PgBouncer Connection Pooling](#9-phase-6-pgbouncer-connection-pooling)
10. [Phase 7: Redis Performance Cache](#10-phase-7-redis-performance-cache)
11. [Phase 8: Node.js, npm, RTL CSS, and Persian Font Support](#11-phase-8-nodejs-npm-rtl-css-and-persian-font-support)
12. [Phase 9: Patched wkhtmltopdf for Persian PDF Reports](#12-phase-9-patched-wkhtmltopdf-for-persian-pdf-reports)
13. [Phase 10: Python 3.12 and Odoo System Dependencies](#13-phase-10-python-312-and-odoo-system-dependencies)
14. [Phase 11: Odoo System User and Repository Deployment](#14-phase-11-odoo-system-user-and-repository-deployment)
15. [Phase 12: Python Virtual Environment and Addon Requirements](#15-phase-12-python-virtual-environment-and-addon-requirements)
16. [Phase 13: Fixed Odoo Configuration File](#16-phase-13-fixed-odoo-configuration-file)
17. [Phase 14: Nginx Reverse Proxy, SSL, WebSocket, and Longpolling](#17-phase-14-nginx-reverse-proxy-ssl-websocket-and-longpolling)
18. [Phase 15: Odoo systemd Service](#18-phase-15-odoo-systemd-service)
19. [Phase 16: Database Initialization and Persian Language Loading](#19-phase-16-database-initialization-and-persian-language-loading)
20. [Phase 17: Start and Verify Odoo](#20-phase-17-start-and-verify-odoo)
21. [Phase 18: Cloudflare Quick Tunnel — Free Public HTTPS](#21-phase-18-cloudflare-quick-tunnel--free-public-https)
22. [Phase 19: Mobile Camera Testing Over HTTPS](#22-phase-19-mobile-camera-testing-over-https)
23. [Persian RTL Support in Odoo 20](#23-persian-rtl-support-in-odoo-20)
24. [PostgreSQL AI and Vector Search Support](#24-postgresql-ai-and-vector-search-support)
25. [Sub Git Addon Folder Management](#25-sub-git-addon-folder-management)
26. [Odoo Addon Development Workflow](#26-odoo-addon-development-workflow)
27. [Persian Translation Workflow for Custom Addons](#27-persian-translation-workflow-for-custom-addons)
28. [Performance Monitoring](#28-performance-monitoring)
29. [Backup and Restore](#29-backup-and-restore)
30. [Log Rotation](#30-log-rotation)
31. [Troubleshooting](#31-troubleshooting)
32. [Final Verification Checklist](#32-final-verification-checklist)

---

## 1. Fixed Deployment Profile

This guide uses fixed values. Do not replace them unless you intentionally rebuild the entire environment.

### 1.1 Target Operating System

| Item | Value |
|---|---|
| OS | Kubuntu 26 / Ubuntu LTS |
| Architecture | x86_64 |
| Recommended minimum RAM | 32 GB |
| Recommended minimum CPU | 8 vCPU |
| Recommended disk | 100 GB NVMe/SSD |

### 1.2 Fixed Paths

| Item | Path |
|---|---|
| Odoo Linux user | `odoo20` |
| Odoo home directory | `/home/odoo20` |
| Odoo project directory | `/home/odoo20/odoo20` |
| Custom addons directory | `/home/odoo20/odoo20/custom_addons` |
| Filestore directory | `/home/odoo20/odoo20/filestore` |
| Logs directory | `/home/odoo20/odoo20/logs` |
| Backups directory | `/home/odoo20/odoo20/backups` |
| Python virtual environment | `/home/odoo20/odoo20/venv` |
| Odoo configuration file | `/home/odoo20/odoo20/odoo.conf` |

### 1.3 Fixed Ports

| Service | Port |
|---|---|
| Nginx public HTTP | 80 |
| Nginx public HTTPS | 443 |
| Odoo internal HTTP | 8020 |
| Odoo evented/WebSocket/longpolling | 8072 |
| PgBouncer | 6432 |
| PostgreSQL | 5432 |
| Redis | 6379 |

### 1.4 Fixed Credentials

These credentials are fixed for your current convenience.

| Item | Value |
|---|---|
| Linux user | `odoo20` |
| Linux password | `999239` |
| PostgreSQL user | `odoo20` |
| PostgreSQL password | `999239` |
| Odoo master password | `999239` |
| Default Odoo database name | `odoo20` |
| Default Odoo admin login | `admin` |

> **Note:** You stated that you do not want to change passwords currently. These fixed passwords are therefore preserved throughout this document.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT BROWSER                           │
│                    English / Persian UI                         │
│                  (Desktop / Mobile Phone)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CLOUDFLARE EDGE NETWORK                        │
│                                                                 │
│  • Terminates public TLS                                        │
│  • Routes traffic through cloudflared Quick Tunnel              │
│  • Provides free trycloudflare.com URL                          │
└────────────────────────────┬────────────────────────────────────┘
                             │ Outbound-only tunnel
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CLOUDFLARED (QUICK)                         │
│                                                                 │
│  • Runs on the same server as Odoo                              │
│  • Forwards HTTPS traffic to Nginx on localhost:443             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                          NGINX                                  │
│                                                                 │
│  • Reverse proxy                                                │
│  • SSL termination (self-signed)                                │
│  • Static asset caching                                         │
│  • Gzip compression                                             │
│  • WebSocket routing: /websocket                                │
│  • Longpolling routing: /longpolling                            │
│  • Proxy to Odoo HTTP port 8020                                 │
│  • Proxy to Odoo evented port 8072                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ODOO 20                                   │
│                                                                 │
│  • Multi-worker mode                                            │
│  • 8 HTTP workers                                               │
│  • 4 cron threads                                               │
│  • Evented worker for WebSocket/longpolling                     │
│  • Proxy mode enabled                                           │
│  • Persian RTL support                                          │
│  • Custom addon development support                             │
│  • pgvector for AI features                                     │
└───────────────┬─────────────────────────────────┬───────────────┘
                │                                 │
                ▼                                 ▼
┌───────────────────────────┐       ┌─────────────────────────────┐
│        PGBOUNCER          │       │           REDIS             │
│                           │       │                             │
│  • Connection pooling     │       │  • Cache                    │
│  • Port 6432              │       │  • Session support          │
│  • SCRAM-SHA-256          │       │  • Port 6379                │
└─────────────┬─────────────┘       └─────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     POSTGRESQL 17                               │
│                                                                 │
│  • Port 5432                                                    │
│  • SCRAM-SHA-256 authentication                                 │
│  • pgvector for AI/vector search                                │
│  • pg_trgm for fuzzy text search                                │
│  • unaccent for Persian/Latin search behavior                   │
│  • pg_stat_statements for query performance analysis            │
│  • Optimized memory and WAL settings                            │
└─────────────────────────────────────────────────────────────────┘
```

> **Note on PgBouncer + Odoo:** PgBouncer in `session` mode is used here to preserve Odoo's longpolling (`LISTEN/NOTIFY`) behavior. Do not switch to `transaction` mode unless you load the OCA `bus_alt_connection` module server-wide.

> **Note on Cloudflare Quick Tunnel + Odoo:** Cloudflare Quick Tunnels create a temporary `trycloudflare.com` URL for your local service. **You do not need a Cloudflare account or domain.** This is ideal for a dev server where you want to test publicly, including mobile camera features that require HTTPS.

---

## 3. Prerequisites

Before starting, ensure:

- You have root or sudo access.
- The server has at least 32 GB RAM and 8 vCPU for the fixed performance profile.
- Ports 80, 443, 8020, 8072, 6432, 5432, and 6379 are handled correctly.
- PostgreSQL, PgBouncer, Redis, Nginx, and Odoo are installed on the same server.
- Your repository `https://github.com/ehsan-r97/odoo20` contains Odoo 20 source code and custom addon folders.

---

## 4. Phase 1: System Preparation

Update the system and install base tools.

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
    build-essential \
    git \
    wget \
    curl \
    rsync \
    unzip \
    jq \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release \
    locales \
    fontconfig \
    tmux \
    screen \
    htop \
    iotop \
    sysstat
```

---

## 5. Phase 2: Persian Locale and Font Preparation

Install UTF-8 locales for English and Persian.

```bash
for loc in en_US.UTF-8 fa_IR.UTF-8; do
    if ! grep -q "^${loc}" /etc/locale.gen; then
        echo "${loc} UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
    fi
    sudo sed -i "s|^# *${loc}|${loc}|" /etc/locale.gen
done

sudo locale-gen
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
```

Install basic font support.

```bash
sudo apt install -y \
    fontconfig \
    fonts-dejavu-core
```

---

## 6. Phase 3: Operating System Performance Tuning

Apply fixed kernel performance settings.

```bash
sudo tee /etc/sysctl.d/99-odoo20-performance.conf > /dev/null <<'EOF'
# ===========================================
# OS Performance Tuning for Odoo 20
# Server: 32 GB RAM
# ===========================================

vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

fs.file-max = 2097152

net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF

sudo sysctl --system
```

Apply file descriptor limits for the Odoo user.

```bash
sudo tee /etc/security/limits.d/99-odoo20.conf > /dev/null <<'EOF'
odoo20 soft nofile 65536
odoo20 hard nofile 65536
odoo20 soft nproc 4096
odoo20 hard nproc 4096
postgres soft nofile 65536
postgres hard nofile 65536
postgres soft nproc 4096
postgres hard nproc 4096
EOF
```

---

## 7. Phase 4: PostgreSQL 17 Installation and Performance Tuning

### 7.1 Add the Official PostgreSQL Repository

This detects the Kubuntu/Ubuntu codename automatically and falls back to `noble-pgdg` if required.

```bash
CODENAME="$(lsb_release -cs)"

sudo install -d /usr/share/postgresql-common/pgdg

sudo curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    https://www.postgresql.org/media/keys/ACCC4CF8.asc

echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" | \
    sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

if ! sudo apt-get update; then
    echo "PostgreSQL repository for ${CODENAME}-pgdg is unavailable. Trying noble-pgdg..."
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt noble-pgdg main" | \
        sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null
    sudo apt-get update
fi
```

### 7.2 Install PostgreSQL 17

Odoo 20 requires PostgreSQL 16 or later.

```bash
sudo apt install -y \
    postgresql-17 \
    postgresql-client-17 \
    postgresql-contrib-17
```

### 7.3 Fixed PostgreSQL Performance Configuration

Create the configuration drop-in directory.

```bash
sudo mkdir -p /etc/postgresql/17/main/conf.d
```

Ensure PostgreSQL loads `conf.d`.

```bash
sudo sed -i "s|^#include_dir = 'conf.d'|include_dir = 'conf.d'|" \
    /etc/postgresql/17/main/postgresql.conf

grep -q "^include_dir = 'conf.d'" /etc/postgresql/17/main/postgresql.conf || \
    echo "include_dir = 'conf.d'" | \
    sudo tee -a /etc/postgresql/17/main/postgresql.conf > /dev/null
```

Write the fixed performance configuration tuned for 32 GB RAM with SSD/NVMe.

```bash
sudo tee /etc/postgresql/17/main/conf.d/99-odoo20-performance.conf > /dev/null <<'EOF'
# ===========================================
# PostgreSQL 17 - Optimized for Odoo 20
# Server: 32 GB RAM, SSD/NVMe, 8 Odoo workers
# ===========================================

listen_addresses = 'localhost'

max_connections = 200
superuser_reserved_connections = 5

shared_buffers = 8GB
effective_cache_size = 24GB
maintenance_work_mem = 1GB
work_mem = 128MB
temp_buffers = 32MB

wal_buffers = 64MB
checkpoint_completion_target = 0.9
max_wal_size = 4GB
min_wal_size = 1GB

random_page_cost = 1.1
effective_io_concurrency = 200

default_statistics_target = 100
huge_pages = try

password_encryption = scram-sha-256

shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all

log_min_duration_statement = 500ms
log_checkpoints = on
log_lock_waits = on
log_temp_files = 0
log_line_prefix = '%m [%p] %q%u@%d '

lc_messages = 'en_US.UTF-8'
EOF
```

### 7.4 Configure PostgreSQL Authentication

Ensure SCRAM-SHA-256 authentication is allowed for local TCP connections.

```bash
grep -q "^host    all             all             127.0.0.1/32            scram-sha-256" /etc/postgresql/17/main/pg_hba.conf || \
echo "host    all             all             127.0.0.1/32            scram-sha-256" | \
    sudo tee -a /etc/postgresql/17/main/pg_hba.conf > /dev/null

grep -q "^host    all             all             ::1/128                 scram-sha-256" /etc/postgresql/17/main/pg_hba.conf || \
echo "host    all             all             ::1/128                 scram-sha-256" | \
    sudo tee -a /etc/postgresql/17/main/pg_hba.conf > /dev/null
```

Restart PostgreSQL.

```bash
sudo pg_ctlcluster 17 main restart || sudo systemctl restart postgresql
sudo systemctl enable postgresql || true
```

### 7.5 Create the Fixed Odoo PostgreSQL User

```bash
sudo -u postgres psql -c "ALTER SYSTEM SET password_encryption = 'scram-sha-256';"
sudo -u postgres psql -c "SELECT pg_reload_conf();"

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='odoo20'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER odoo20 WITH PASSWORD '999239' CREATEDB SUPERUSER;"

sudo -u postgres psql -c "ALTER USER odoo20 WITH PASSWORD '999239' CREATEDB SUPERUSER;"
```

---

## 8. Phase 5: PostgreSQL AI/Vector Extensions

Install PostgreSQL extensions required for AI, vector search, fuzzy search, Persian/Latin search behavior, and performance analysis.

### 8.1 Install pgvector

Try the packaged version first.

```bash
sudo apt install -y postgresql-17-pgvector
```

If the package is unavailable, compile pgvector from source.

```bash
if ! dpkg -s postgresql-17-pgvector >/dev/null 2>&1; then
    sudo apt install -y postgresql-server-dev-17 build-essential git

    rm -rf /tmp/pgvector
    git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git /tmp/pgvector

    make -C /tmp/pgvector
    sudo make -C /tmp/pgvector install
fi
```

### 8.2 Enable Extensions in template1

Extensions enabled in `template1` are inherited by newly created Odoo databases.

```bash
for ext in vector pg_trgm unaccent pg_stat_statements; do
    sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS ${ext};"
done
```

---

## 9. Phase 6: PgBouncer Connection Pooling

Install PgBouncer.

```bash
sudo apt install -y pgbouncer
```

Write the fixed PgBouncer configuration.

```bash
sudo tee /etc/pgbouncer/pgbouncer.ini > /dev/null <<'EOF'
[databases]
* = host=127.0.0.1 port=5432

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432

auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

admin_users = odoo20
stats_users = odoo20

pool_mode = session

max_client_conn = 500
default_pool_size = 80
min_pool_size = 10

reserve_pool_size = 10
reserve_pool_timeout = 3

server_idle_timeout = 600
server_lifetime = 3600
server_login_retry = 3

query_wait_timeout = 120
client_login_timeout = 60

tcp_keepalive = 1
tcp_keepcnt = 3
tcp_keepidle = 30
tcp_keepintvl = 10

ignore_startup_parameters = extra_float_digits
EOF
```

Extract the PostgreSQL SCRAM secret and place it into PgBouncer.

```bash
SCRAM_SECRET=$(sudo -u postgres psql -Atc "SELECT rolpassword FROM pg_authid WHERE rolname='odoo20';")

printf '"odoo20" "%s"\n' "$SCRAM_SECRET" | \
    sudo tee /etc/pgbouncer/userlist.txt > /dev/null

sudo chown pgbouncer:pgbouncer /etc/pgbouncer/userlist.txt
sudo chmod 600 /etc/pgbouncer/userlist.txt
```

Enable and restart PgBouncer.

```bash
sudo systemctl enable --now pgbouncer
sudo systemctl restart pgbouncer
```

Test PgBouncer authentication.

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d postgres -c "SELECT 1;"
```

Expected result:

```
 ?column?
----------
        1
(1 row)
```

---

## 10. Phase 7: Redis Performance Cache

Install Redis.

```bash
sudo apt install -y redis-server
```

Append fixed Redis performance settings if they are not already present.

```bash
grep -q "^maxmemory 1073741824" /etc/redis/redis.conf || \
sudo tee -a /etc/redis/redis.conf > /dev/null <<'EOF'

# Odoo 20 fixed Redis performance settings
maxmemory 1073741824
maxmemory-policy allkeys-lru
appendonly no
save ""
timeout 0
tcp-keepalive 300
EOF
```

Enable and restart Redis.

```bash
sudo systemctl enable --now redis-server
sudo systemctl restart redis-server
```

Test Redis.

```bash
redis-cli ping
```

Expected result:

```
PONG
```

---

## 11. Phase 8: Node.js, npm, RTL CSS, and Persian Font Support

Odoo frontend assets and RTL transformation may require Node.js, npm, Less, and RTL CSS tooling.

Install Node.js and related packages.

```bash
sudo apt install -y \
    nodejs \
    npm \
    node-less \
    xfonts-75dpi \
    xfonts-base
```

Ensure the `node` binary is available.

```bash
sudo ln -sf /usr/bin/nodejs /usr/bin/node || true
```

Install global RTL and Less tools.

```bash
sudo npm install -g rtlcss less less-plugin-clean-css
```

Install Persian/Arabic-script compatible fonts.

```bash
sudo apt install -y \
    fonts-noto-core \
    fonts-noto-ui-core \
    fonts-kacst \
    fonts-kacst-one \
    fontconfig
```

Install Vazirmatn fonts for better Persian rendering.

```bash
sudo mkdir -p /usr/local/share/fonts/vazirmatn

for weight in Regular Medium SemiBold Bold Light; do
    sudo curl -fsSL -o "/usr/local/share/fonts/vazirmatn/Vazirmatn-${weight}.ttf" \
        "https://github.com/rastikerdar/vazirmatn/raw/master/fonts/ttf/Vazirmatn-${weight}.ttf" || true
done

sudo fc-cache -fv
```

Verify font matching.

```bash
fc-match "Vazirmatn"
fc-match "Noto Naskh Arabic"
fc-match "KacstOne"
```

Verify Node.js tools.

```bash
node -v
npm -v
rtlcss --version || true
```

---

## 12. Phase 9: Patched wkhtmltopdf for Persian PDF Reports

Odoo requires a patched `wkhtmltopdf` build for reliable PDF headers, footers, and complex rendering.

Use the following installer. It tries newer Ubuntu codenames first and falls back to older compatible packages.

```bash
install_wkhtmltopdf() {
    BASE_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3"

    for codename in noble jammy bionic; do
        PKG="wkhtmltox_0.12.6.1-3.${codename}_amd64.deb"

        if curl -fsIL "${BASE_URL}/${PKG}" > /dev/null; then
            wget "${BASE_URL}/${PKG}"

            sudo dpkg -i "${PKG}" || true
            sudo apt --fix-broken install -y

            rm -f "${PKG}"
            return 0
        fi
    done

    return 1
}

if ! install_wkhtmltopdf; then
    echo "No suitable patched wkhtmltopdf package found. Trying distribution package..."
    sudo apt install -y wkhtmltopdf || true
fi
```

Verify `wkhtmltopdf`.

```bash
wkhtmltopdf --version
```

You should see a patched build, ideally containing:

```
with patched qt
```

If it is not patched, Persian PDF reports may render incorrectly.

---

## 13. Phase 10: Python 3.12 and Odoo System Dependencies

Odoo 20 in this guide uses Python 3.12.

If Python 3.12 is not available in the default repositories, add the DeadSnakes PPA.

```bash
if ! apt-cache show python3.12 > /dev/null 2>&1; then
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
fi
```

Install Python 3.12.

```bash
sudo apt install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip
```

Install Odoo system dependencies.

```bash
sudo apt install -y \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    libffi-dev \
    libpq-dev \
    libjpeg-dev \
    liblcms2-dev \
    libtiff5-dev \
    libwebp-dev \
    libfreetype-dev \
    libblas-dev \
    libatlas-base-dev \
    libzip-dev
```

---

## 14. Phase 11: Odoo System User and Repository Deployment

Create the fixed Linux user.

```bash
sudo useradd -m -s /bin/bash odoo20 || true
echo "odoo20:999239" | sudo chpasswd
```

Create fixed directories.

```bash
sudo mkdir -p /home/odoo20/odoo20/{custom_addons,filestore,logs,backups}
```

Deploy the repository.

If `/home/odoo20/odoo20` is empty or does not contain a Git repository, clone the repository into a temporary directory and synchronize it into the final project directory. This preserves existing custom addon folders.

```bash
sudo -iu odoo20 bash -s <<'EOS'
set -e

if [ ! -d /home/odoo20/odoo20/.git ]; then
    rm -rf /home/odoo20/odoo20-src
    git clone https://github.com/ehsan-r97/odoo20.git /home/odoo20/odoo20-src
    rsync -a /home/odoo20/odoo20-src/ /home/odoo20/odoo20/
    rm -rf /home/odoo20/odoo20-src
fi
EOS
```

Set permissions.

```bash
sudo chown -R odoo20:odoo20 /home/odoo20/odoo20
sudo chmod 755 /home/odoo20/odoo20/custom_addons
```

---

## 15. Phase 12: Python Virtual Environment and Addon Requirements

Create and populate the Python virtual environment.

```bash
sudo -iu odoo20 bash -s <<'EOS'
set -e

cd /home/odoo20/odoo20

if [ ! -d venv ]; then
    python3.12 -m venv venv
fi

source venv/bin/activate

pip install --upgrade pip setuptools wheel

pip install -r requirements.txt

pip install \
    psycopg2-binary \
    "psycopg[binary]" \
    PyYAML \
    python-dotenv \
    redis \
    phonenumbers \
    pgvector \
    numpy \
    requests

if [ -d custom_addons ]; then
    find custom_addons -type f -name "requirements.txt" -print0 | \
    while IFS= read -r -d '' req_file; do
        echo "Installing dependencies from: ${req_file}"
        pip install -r "${req_file}"
    done
fi
EOS
```

---

## 16. Phase 13: Fixed Odoo Configuration File

Write the fixed `/home/odoo20/odoo20/odoo.conf`.

```bash
sudo tee /home/odoo20/odoo20/odoo.conf > /dev/null <<'EOF'
[options]

; =============================================================================
; SERVER
; =============================================================================
http_interface = 127.0.0.1
http_port = 8020
gevent_port = 8072
proxy_mode = True
server_wide_modules = base,web

; =============================================================================
; DATABASE THROUGH PGBOUNCER
; =============================================================================
db_host = 127.0.0.1
db_port = 6432
db_user = odoo20
db_password = 999239

db_maxconn = 32
db_sslmode = prefer
dbfilter = ^.*$
db_template = template1
unaccent = True

; =============================================================================
; ADDONS AND FILESTORE
; =============================================================================
addons_path = /home/odoo20/odoo20/odoo/addons,/home/odoo20/odoo20/addons,/home/odoo20/odoo20/custom_addons
data_dir = /home/odoo20/odoo20/filestore

; =============================================================================
; SECURITY / MASTER PASSWORD
; =============================================================================
admin_passwd = 999239
list_db = True

; =============================================================================
; LOGGING
; =============================================================================
logfile = /home/odoo20/odoo20/logs/odoo.log
log_level = info
log_handler = :INFO,werkzeug:WARNING,odoo.modules.registry:WARNING,odoo.addons.base.models.ir_attachment:WARNING

; =============================================================================
; PERFORMANCE / WORKERS (8 workers for 32GB RAM)
; =============================================================================
workers = 8
max_cron_threads = 4

limit_memory_soft = 1073741824
limit_memory_hard = 1610612736

limit_time_cpu = 600
limit_time_real = 1200
limit_request = 1073741824

; =============================================================================
; TRANSLATION / PERSIAN SUPPORT
; =============================================================================
translate_modules = ['all']

; =============================================================================
; DEVELOPMENT / PRODUCTION SWITCH
; =============================================================================
dev_mode = False
demo = False
EOF

sudo chown odoo20:odoo20 /home/odoo20/odoo20/odoo.conf
sudo chmod 640 /home/odoo20/odoo20/odoo.conf
```

### Configuration Notes

| Parameter | Fixed Value | Reason |
|---|---|---|
| `http_port` | 8020 | Odoo listens locally behind Nginx |
| `gevent_port` | 8072 | WebSocket/longpolling/evented service |
| `proxy_mode` | True | Required behind Nginx and Cloudflare Tunnel |
| `db_port` | 6432 | Uses PgBouncer |
| `db_template` | template1 | Inherits PostgreSQL AI/search extensions |
| `workers` | 8 | Balanced for 32 GB RAM with 8+ vCPU |
| `max_cron_threads` | 4 | Background job capacity |
| `limit_memory_soft` | 1 GB | Worker soft restart threshold |
| `limit_memory_hard` | 1.5 GB | Worker hard memory limit |
| `limit_time_cpu` | 600 | Allow long-running reports/imports |
| `limit_time_real` | 1200 | Allow long-running reports/imports |
| `unaccent` | True | Better search behavior |
| `translate_modules` | all | Loads translation support for all modules |

---

## 17. Phase 14: Nginx Reverse Proxy, SSL, WebSocket, and Longpolling

### 17.1 Install Nginx

```bash
sudo apt install -y nginx
```

### 17.2 Self-Signed SSL Certificate (Required for Local HTTPS + Camera Testing)

```bash
sudo mkdir -p /etc/nginx/ssl

sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/odoo20.key \
    -out /etc/nginx/ssl/odoo20.crt \
    -subj "/C=IR/ST=Tehran/L=Tehran/O=Dev/CN=localhost"
```

### 17.3 Write the Fixed Main Nginx Configuration

```bash
sudo tee /etc/nginx/nginx.conf > /dev/null <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 4096;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    keepalive_timeout 65;
    types_hash_max_size 2048;

    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1100;

    gzip_types
        text/css
        text/plain
        text/xml
        application/xml
        application/json
        application/javascript
        application/x-javascript
        image/svg+xml
        font/woff
        font/woff2;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
```

### 17.4 Write the Fixed Odoo Site Configuration

```bash
sudo tee /etc/nginx/sites-available/odoo20 > /dev/null <<'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

upstream odoo {
    server 127.0.0.1:8020;
    keepalive 64;
}

upstream odoochat {
    server 127.0.0.1:8072;
    keepalive 64;
}

server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    http2 on;
    server_name _;

    ssl_certificate /etc/nginx/ssl/odoo20.crt;
    ssl_certificate_key /etc/nginx/ssl/odoo20.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;

    client_max_body_size 0;
    client_body_buffer_size 128k;

    proxy_connect_timeout 900s;
    proxy_send_timeout 900s;
    proxy_read_timeout 900s;

    reset_timedout_connection on;

    gzip on;
    gzip_min_length 1100;
    gzip_buffers 4 32k;
    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
    gzip_vary on;

    location / {
        proxy_pass http://odoo;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }

    location /websocket {
        proxy_pass http://odoochat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }

    location /longpolling {
        proxy_pass http://odoochat;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 7d;
        add_header Cache-Control "public, no-transform";
        proxy_pass http://odoo;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
EOF
```

> **Important:** The `X-Forwarded-Host` header is required for Odoo to correctly detect the public hostname when behind Cloudflare Tunnel. Without it, Odoo may generate incorrect URLs, causing CSRF and session issues.

### 17.5 Enable the Site

```bash
sudo ln -sf /etc/nginx/sites-available/odoo20 /etc/nginx/sites-enabled/odoo20
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl restart nginx
```

---

## 18. Phase 15: Odoo systemd Service

Create the fixed systemd service.

```bash
sudo tee /etc/systemd/system/odoo20.service > /dev/null <<'EOF'
[Unit]
Description=Odoo 20
After=network-online.target postgresql.service pgbouncer.service redis-server.service
Wants=network-online.target

[Service]
Type=simple
User=odoo20
Group=odoo20
WorkingDirectory=/home/odoo20/odoo20

ExecStart=/home/odoo20/odoo20/venv/bin/python3 /home/odoo20/odoo20/odoo-bin -c /home/odoo20/odoo20/odoo.conf

Restart=on-failure
RestartSec=5

LimitNOFILE=65536
LimitNPROC=4096

StandardOutput=journal
StandardError=journal
SyslogIdentifier=odoo20

[Install]
WantedBy=multi-user.target
EOF
```

Reload systemd.

```bash
sudo systemctl daemon-reload
```

Do not start Odoo yet. Initialize the database first.

---

## 19. Phase 16: Database Initialization and Persian Language Loading

Stop Odoo if it is running.

```bash
sudo systemctl stop odoo20 || true
```

Initialize the database, enable PostgreSQL extensions inside the Odoo database, load Persian, and regenerate base/web assets.

```bash
sudo -iu odoo20 bash -s <<'EOS'
set -e

cd /home/odoo20/odoo20
source venv/bin/activate

DB="odoo20"

echo "Checking whether database ${DB} exists..."

if ! PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d postgres -Atc \
    "SELECT 1 FROM pg_database WHERE datname='${DB}'" | grep -q 1; then

    echo "Creating database ${DB}..."
    ./odoo-bin -c odoo.conf -d "${DB}" -i base --stop-after-init
else
    echo "Database ${DB} already exists."
fi

echo "Ensuring PostgreSQL extensions exist inside ${DB}..."

PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d "${DB}" -c \
"CREATE EXTENSION IF NOT EXISTS vector;
 CREATE EXTENSION IF NOT EXISTS pg_trgm;
 CREATE EXTENSION IF NOT EXISTS unaccent;
 CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

echo "Loading Persian language and updating base/web assets..."

./odoo-bin -c odoo.conf -d "${DB}" \
    --load-language=fa_IR \
    -u base,web \
    --stop-after-init
EOS
```

---

## 20. Phase 17: Start and Verify Odoo

Start Odoo.

```bash
sudo systemctl enable --now odoo20
sudo systemctl status odoo20 --no-pager
```

Check listening ports.

```bash
sudo ss -ltnp | grep -E ':(80|443|6432|8020|8072|5432|6379)\b'
```

Expected services:

| Port | Service |
|---|---|
| 80 | Nginx HTTP |
| 443 | Nginx HTTPS |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 6432 | PgBouncer |
| 8020 | Odoo HTTP |
| 8072 | Odoo evented/WebSocket/longpolling |

Test HTTP.

```bash
curl -I http://127.0.0.1
```

You should receive an HTTP redirect to HTTPS. Then test HTTPS (ignore self-signed cert):

```bash
curl -k -I https://127.0.0.1
```

You should receive an Odoo HTTP response, commonly a redirect such as:

```
HTTP/1.1 303 SEE OTHER
```

Open in browser:

```
https://127.0.0.1
```

Or from another machine on your network:

```
https://SERVER_IP
```

Default database:

```
odoo20
```

Master password:

```
999239
```

---

## 21. Phase 18: Cloudflare Quick Tunnel — Free Public HTTPS

Cloudflare Quick Tunnels create a temporary `trycloudflare.com` URL for your local service. **You do not need a Cloudflare account or domain.** This is ideal for a dev server where you want to test publicly, including mobile camera features that require HTTPS.

### 21.1 Download and Install cloudflared

```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
chmod +x cloudflared

sudo mv cloudflared /usr/local/bin/cloudflared

cloudflared --version
```

### 21.2 Start the Quick Tunnel to Nginx on Port 443

Run this command **while Nginx and Odoo are running**:

```bash
cloudflared tunnel --url https://localhost:443 --no-tls-verify
```

> **Note on `--no-tls-verify`:** Since Nginx is using a self-signed certificate, cloudflared needs to skip TLS verification when connecting to the origin. This is safe because the connection between cloudflared and Nginx is local (localhost).

### 21.3 What You'll See

After running the command, cloudflared will output a random URL like:

```
https://random-words-1234.trycloudflare.com
```

**Anyone with this URL can access your local Odoo instance over HTTPS.** The URL stops working when you stop the `cloudflared` process.

### 21.4 Keep the Tunnel Alive

Use `tmux` or `screen` to keep the tunnel running after logout:

```bash
tmux new -s cloudflared
cloudflared tunnel --url https://localhost:443 --no-tls-verify
# Ctrl+B, then D to detach
```

To reattach:

```bash
tmux attach -t cloudflared
```

### 21.5 Restrict Access by Email (Optional)

You can require email authentication so only specific people can access your Odoo:

```bash
cloudflared tunnel --url https://localhost:443 --no-tls-verify \
  --allowed-mail your-email@example.com
```

Visitors receive a one-time PIN before they can access your service.

### 21.6 Verify the Tunnel Works with Nginx

1. Ensure Nginx is running: `sudo systemctl status nginx`
2. Ensure Odoo is running: `sudo systemctl status odoo20`
3. Run the cloudflared command above.
4. Open the printed `trycloudflare.com` URL in your browser.
5. You should see the Odoo login page over HTTPS.

If you see a 502 Bad Gateway, check that Nginx is listening on port 443 and that the self-signed certificate is valid.

### 21.7 Quick Tunnel Limitations

| Limitation | Value |
|---|---|
| Uptime guarantee | None (testing/development only) |
| Concurrent in-flight requests | 200 (429 if exceeded) |
| Server-Sent Events (SSE) | Not supported |
| URL stability | Changes on every restart |

> **Important:** Quick Tunnels are for testing and development, not production. For a stable URL, you would need a named tunnel with a Cloudflare account and domain, but that is not required for this dev setup.

---

## 22. Phase 19: Mobile Camera Testing Over HTTPS

Odoo's camera widget (used in Barcode, Inventory, Quality, and custom modules) requires **HTTPS** on mobile browsers. Browsers block camera access on insecure HTTP origins.

### 22.1 Why HTTPS Is Required for Camera

- Chrome, Safari, and Firefox on mobile require a **secure context** (`https://` or `localhost`) to grant camera permissions via `navigator.mediaDevices.getUserMedia()`.
- Since your Odoo dev server has a self-signed certificate, direct access from a phone will show a certificate warning.
- Cloudflare Quick Tunnel solves this by providing a **valid public HTTPS URL** that proxies to your local Odoo.

### 22.2 Steps to Test Camera on Your Phone

1. Ensure Odoo is running:
   ```bash
   sudo systemctl status odoo20
   ```

2. Ensure Nginx is running with SSL:
   ```bash
   sudo systemctl status nginx
   ```

3. Start the Cloudflare Quick Tunnel:
   ```bash
   cloudflared tunnel --url https://localhost:443 --no-tls-verify
   ```

4. Copy the printed `https://xxxx.trycloudflare.com` URL.

5. On your phone, open the URL in Chrome or Safari.

6. Log in to Odoo.

7. Open a module that uses the camera widget, for example:
   - **Inventory → Barcode** (scan with camera)
   - **Quality → Quality Check** (attach photo)
   - **Contacts → Attachment** (take photo)

8. When the browser asks for **Camera permission**, tap **Allow**.

9. The camera preview should appear and capture should work.

### 22.3 Troubleshooting Camera Issues

**Issue: "Camera not allowed" or "Permission denied"**

- Confirm the URL starts with `https://`.
- Confirm you tapped **Allow** on the browser permission prompt.
- Check your phone's browser settings: camera permission must not be blocked for the site.
- On iOS Safari, go to **Settings → Safari → Camera** and ensure it is set to **Ask** or **Allow**.

**Issue: Camera preview is black or frozen**

- The Quick Tunnel may be rate-limited. Try again after a few seconds.
- Confirm Odoo's asset bundles were regenerated (`-u base,web`).
- Clear browser cache on the phone (`Ctrl+Shift+R` is not available on mobile; use browser settings).

**Issue: Redirect loop after login**

- Ensure `proxy_mode = True` in `odoo.conf`.
- Ensure Nginx forwards `X-Forwarded-Proto` and `X-Forwarded-Host`.

**Issue: CSRF token errors**

- Same as above: `proxy_mode = True` and `X-Forwarded-Host` header are mandatory.

### 22.4 Recommended Mobile Testing Workflow

| Step | Action |
|---|---|
| 1 | Start Odoo: `sudo systemctl start odoo20` |
| 2 | Start Nginx: `sudo systemctl start nginx` |
| 3 | Start tunnel: `cloudflared tunnel --url https://localhost:443 --no-tls-verify` |
| 4 | Copy the `trycloudflare.com` URL |
| 5 | Open the URL on your phone |
| 6 | Log in as `admin` |
| 7 | Navigate to a camera-enabled module |
| 8 | Grant camera permission |
| 9 | Test scanning / photo capture |
| 10 | When done, stop cloudflared with `Ctrl+C` |

---

## 23. Persian RTL Support in Odoo 20

This installation supports Persian `fa_IR` only. Arabic is not configured.

### 23.1 System-Level Persian Support

Already installed:

- Persian locale: `fa_IR.UTF-8`
- UTF-8 encoding
- Vazirmatn fonts
- Noto fonts
- Kacst fonts
- Fontconfig cache
- Patched wkhtmltopdf
- Node.js
- npm
- rtlcss
- Less
- clean-css

These components support:

- Persian browser UI.
- Persian RTL layout.
- Persian input.
- Persian PDF reports.
- Correct glyph rendering.
- Right-to-left CSS transformation.

### 23.2 Activate Persian Inside Odoo

1. Log in as administrator.
2. Go to:
   ```
   Settings → Translations → Languages
   ```
3. Activate:
   ```
   Persian (fa_IR)
   ```
4. Open the Persian language record.
5. Confirm direction is:
   ```
   RTL
   ```
6. Load translations.

If the language does not appear correctly, force the RTL direction at database level:

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 -c \
"UPDATE res_lang SET direction = 'rtl' WHERE code = 'fa_IR';"
```

Then restart Odoo:

```bash
sudo systemctl restart odoo20
```

### 23.3 Set User Language to Persian

1. Go to:
   ```
   Settings → Users and Companies → Users
   ```
2. Open your user.
3. Set:
   ```
   Language = Persian (fa_IR)
   ```
4. Save.
5. Log out.
6. Log in again.

The interface should render right-to-left.

### 23.4 Persian PDF Reports

For Persian PDF reports, ensure:

- The partner/company language is Persian where relevant.
- `wkhtmltopdf` is patched.
- Vazirmatn/Noto/Kacst fonts are installed.
- Odoo assets have been regenerated.

Regenerate assets:

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate
./odoo-bin -c odoo.conf -d odoo20 -u base,web --stop-after-init
EOS

sudo systemctl start odoo20
```

Clear browser cache and perform a hard refresh:

```
Ctrl + Shift + R
```

### 23.5 Custom Addon RTL Best Practices

When developing custom addons:

- Do not hardcode left and right CSS properties when possible.
- Prefer logical properties:
  - `margin-inline-start`
  - `margin-inline-end`
  - `padding-inline-start`
  - `padding-inline-end`
  - `text-align: start`
  - `text-align: end`
- Include CSS files in Odoo asset bundles.
- After changing assets, upgrade `web` or your module.
- Test with user language `fa_IR`.

---

## 24. PostgreSQL AI and Vector Search Support

This installation includes PostgreSQL AI/vector support using `pgvector`.

### 24.1 Installed AI/Search Extensions

The following extensions are enabled:

| Extension | Purpose |
|---|---|
| `vector` | Vector similarity search for AI/RAG |
| `pg_trgm` | Trigram fuzzy text search |
| `unaccent` | Accent-insensitive search |
| `pg_stat_statements` | Query performance analysis |

### 24.2 Python AI Packages

Installed in the Odoo virtual environment:

- `pgvector`
- `numpy`
- `requests`
- `psycopg2-binary`
- `psycopg[binary]`

These support:

- Vector insertion.
- Vector similarity queries.
- Embedding storage.
- AI-related Python integrations.

### 24.3 Optional Local AI Backend with Ollama

If you want local embeddings and local AI inference, install Ollama.

```bash
curl -fsSL https://ollama.com/install.sh | sh

sudo systemctl enable --now ollama
```

Pull a Persian/English compatible embedding model.

```bash
ollama pull nomic-embed-text
```

Test:

```bash
ollama run nomic-embed-text "test"
```

Ollama listens on:

```
127.0.0.1:11434
```

### 24.4 Example Vector Table for AI Documents

This example uses 768 dimensions, compatible with `nomic-embed-text`.

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 <<'EOS'
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS ai_document_embedding (
    id BIGSERIAL PRIMARY KEY,
    res_model VARCHAR NOT NULL,
    res_id BIGINT NOT NULL,
    chunk_text TEXT NOT NULL,
    embedding vector(768) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ai_document_embedding_res_idx
ON ai_document_embedding (res_model, res_id);

CREATE INDEX IF NOT EXISTS ai_document_embedding_vector_idx
ON ai_document_embedding
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
EOS
```

Example similarity query:

```sql
SELECT
    res_model,
    res_id,
    chunk_text,
    1 - (embedding <=> CAST(:embedding AS vector)) AS similarity
FROM ai_document_embedding
ORDER BY embedding <=> CAST(:embedding AS vector)
LIMIT 5;
```

### 24.5 AI Performance Notes

For large vector tables:

- Use `ivfflat` for moderate datasets.
- Use `hnsw` if your pgvector version supports it and your dataset is large.
- Keep embeddings normalized when using cosine distance.
- Monitor slow queries using `pg_stat_statements`.

---

## 25. Sub Git Addon Folder Management

Your repository is designed to contain multiple independent Git-based addon folders, usually under:

```
/home/odoo20/odoo20/custom_addons
```

Example:

```
/home/odoo20/odoo20/custom_addons/my_first_addon
/home/odoo20/odoo20/custom_addons/my_second_addon
/home/odoo20/odoo20/custom_addons/customer_specific_module
```

Each addon folder may have its own `.git` directory.

### 25.1 Recommended Parent Repository Policy

The parent Odoo repository should not track the internal contents of independent addon repositories.

Create or update `.gitignore` in the parent repository:

```bash
sudo tee /home/odoo20/odoo20/.gitignore > /dev/null <<'EOF'
# Python
__pycache__/
*.py[cod]
*.egg-info/
.eggs/

# Virtual environment
venv/

# Odoo runtime data
filestore/
logs/
backups/

# Environment files
.env

# Editors
.idea/
.vscode/
*.swp

# Node
node_modules/

# Independent addon Git repositories
custom_addons/*
!custom_addons/.gitkeep
EOF

sudo chown odoo20:odoo20 /home/odoo20/odoo20/.gitignore
```

Create the keep file:

```bash
sudo -iu odoo20 touch /home/odoo20/odoo20/custom_addons/.gitkeep
```

### 25.2 If an Addon Folder Was Already Added to the Parent Repository

Remove it from the parent index without deleting local files:

```bash
cd /home/odoo20/odoo20
git rm -r --cached custom_addons/ADDON_NAME
```

Replace `ADDON_NAME` with the actual addon folder name.

Then commit:

```bash
git commit -m "Stop tracking independent addon repository"
```

### 25.3 Update All Independent Addon Repositories

```bash
sudo -iu odoo20 bash -s <<'EOS'
set -e

cd /home/odoo20/odoo20/custom_addons

for addon_dir in */; do
    if [ -d "${addon_dir}/.git" ]; then
        echo "------------------------------------------------------------"
        echo "Updating: ${addon_dir}"
        echo "------------------------------------------------------------"
        git -C "${addon_dir}" fetch --all --prune
        git -C "${addon_dir}" pull --ff-only
    fi
done
EOS
```

### 25.4 Show Status of All Independent Addon Repositories

```bash
sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20/custom_addons

for addon_dir in */; do
    if [ -d "${addon_dir}/.git" ]; then
        echo "------------------------------------------------------------"
        echo "Status: ${addon_dir}"
        echo "------------------------------------------------------------"
        git -C "${addon_dir}" status --short --branch
    fi
done
EOS
```

### 25.5 Alternative: Use Git Submodules

If you want the parent repository to pin exact addon commits, convert addon folders to Git submodules.

Example:

```bash
cd /home/odoo20/odoo20

git submodule add https://github.com/your-org/your-addon.git custom_addons/your-addon
git submodule update --init --recursive
```

For this repository, independent sub-Git folders are supported either by:

- Ignoring them in the parent repository, or
- Tracking them as Git submodules.

Choose one approach and keep it consistent.

---

## 26. Odoo Addon Development Workflow

This repository is intended for Odoo addon development.

### 26.1 Create a New Addon Scaffold

```bash
sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate

./odoo-bin scaffold new_addon custom_addons
EOS
```

This creates:

```
/home/odoo20/odoo20/custom_addons/new_addon
```

### 26.2 Initialize the New Addon as Its Own Git Repository

```bash
sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20/custom_addons/new_addon

git init
git add .
git commit -m "Initial Odoo 20 addon structure"
EOS
```

Then connect it to your remote repository:

```bash
cd /home/odoo20/odoo20/custom_addons/new_addon
git remote add origin https://github.com/your-org/new_addon.git
git push -u origin main
```

### 26.3 Install a New Addon

Stop Odoo:

```bash
sudo systemctl stop odoo20
```

Update the application list:

```bash
sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate

./odoo-bin -c odoo.conf -d odoo20 -u base --stop-after-init
EOS
```

Start Odoo:

```bash
sudo systemctl start odoo20
```

Then install from UI:

```
Apps → Update Apps List → Search new_addon → Install
```

### 26.4 Upgrade an Existing Addon

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate

./odoo-bin -c odoo.conf -d odoo20 -u new_addon --stop-after-init
EOS

sudo systemctl start odoo20
```

### 26.5 Upgrade Multiple Addons

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate

./odoo-bin -c odoo.conf -d odoo20 \
    -u new_addon,another_addon,base,web \
    --stop-after-init
EOS

sudo systemctl start odoo20
```

### 26.6 Run Odoo in Development Mode Manually

Use this only for development.

```bash
sudo systemctl stop odoo20

sudo apt install -y tmux || true

tmux new -s odoo20-dev

sudo -iu odoo20 bash -lc '
cd /home/odoo20/odoo20
source venv/bin/activate
./odoo-bin -c odoo.conf -d odoo20 --dev=reload,qweb,xml
'
```

Detach from tmux:

```
Ctrl+B then D
```

Attach later:

```bash
tmux attach -t odoo20-dev
```

Stop manual development mode and return to service:

```bash
tmux kill-session -t odoo20-dev || true
sudo systemctl start odoo20
```

### 26.7 Run Automated Tests for an Addon

Create a separate test database:

```bash
sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate

./odoo-bin -c odoo.conf \
    -d test_odoo20 \
    -i new_addon \
    --test-enable \
    --stop-after-init
EOS
```

Delete the test database when finished:

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d postgres -c "DROP DATABASE IF EXISTS test_odoo20;"
```

---

## 27. Persian Translation Workflow for Custom Addons

### 27.1 Add Persian Translation Files

Inside your addon, create:

```
custom_addons/new_addon/i18n/fa_IR.po
```

Odoo translation files usually live in:

```
addon_name/i18n/
```

### 27.2 Update Persian Translations from Code

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate

./odoo-bin -c odoo.conf \
    -d odoo20 \
    -u new_addon \
    --load-language=fa_IR \
    --stop-after-init
EOS

sudo systemctl start odoo20
```

### 27.3 Export Persian Translations from Odoo UI

Go to:

```
Settings → Translations → Export Translation
```

Select:

```
Language: Persian (fa_IR)
Format: Gettext Po file
```

Export and place the file inside your addon:

```
custom_addons/new_addon/i18n/fa_IR.po
```

### 27.4 Import Persian Translations into Odoo

Go to:

```
Settings → Translations → Import Translations
```

Upload:

```
fa_IR.po
```

Then upgrade the module:

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate
./odoo-bin -c odoo.conf -d odoo20 -u new_addon --stop-after-init
EOS

sudo systemctl start odoo20
```

---

## 28. Performance Monitoring

### 28.1 Odoo Service Logs

```bash
sudo journalctl -u odoo20 -f
```

Odoo file log:

```bash
tail -f /home/odoo20/odoo20/logs/odoo.log
```

### 28.2 PostgreSQL Slow Queries

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 -c \
"SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;"
```

### 28.3 Active PostgreSQL Connections

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d postgres -c \
"SELECT
    state,
    count(*)
FROM pg_stat_activity
GROUP BY state
ORDER BY count DESC;"
```

### 28.4 PgBouncer Statistics

Connect to the PgBouncer admin database:

```bash
psql -h 127.0.0.1 -p 6432 -U odoo20 -d pgbouncer
```

Run:

```
SHOW STATS;
SHOW POOLS;
SHOW CLIENTS;
SHOW SERVERS;
```

Exit:

```
\q
```

### 28.5 Redis Statistics

```bash
redis-cli info stats
redis-cli info memory
redis-cli client list
```

### 28.6 Nginx Status

```bash
sudo systemctl status nginx --no-pager
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### 28.7 System Resource Usage

```bash
htop
```

If `htop` is not installed:

```bash
sudo apt install -y htop
```

Check disk:

```bash
df -h
```

Check memory:

```bash
free -h
```

Check open ports:

```bash
sudo ss -ltnp
```

---

## 29. Backup and Restore

### 29.1 Full Backup

This backup stops Odoo, dumps PostgreSQL, copies filestore, copies custom addons, copies logs, and restarts Odoo.

```bash
sudo systemctl stop odoo20

BACKUP_DIR="/home/odoo20/odoo20/backups/manual_$(date +%Y%m%d_%H%M%S)"
sudo -u odoo20 mkdir -p "${BACKUP_DIR}"

PGPASSWORD='999239' pg_dump \
    -h 127.0.0.1 \
    -p 5432 \
    -U odoo20 \
    -Fc \
    odoo20 > "${BACKUP_DIR}/odoo20.dump"

sudo -u odoo20 rsync -a /home/odoo20/odoo20/filestore "${BACKUP_DIR}/filestore"
sudo -u odoo20 rsync -a /home/odoo20/odoo20/custom_addons "${BACKUP_DIR}/custom_addons"
sudo -u odoo20 cp /home/odoo20/odoo20/odoo.conf "${BACKUP_DIR}/odoo.conf"
sudo -u odoo20 tar -czf "${BACKUP_DIR}/logs.tar.gz" -C /home/odoo20/odoo20 logs

sudo chown -R odoo20:odoo20 "${BACKUP_DIR}"

sudo systemctl start odoo20

echo "Backup created at: ${BACKUP_DIR}"
```

### 29.2 Restore Full Backup

Replace `BACKUP_PATH` with the actual backup directory.

```bash
BACKUP_PATH="/home/odoo20/odoo20/backups/manual_YYYYMMDD_HHMMSS"

sudo systemctl stop odoo20

PGPASSWORD='999239' psql -h 127.0.0.1 -p 5432 -U odoo20 -d postgres -c "DROP DATABASE IF EXISTS odoo20;"
PGPASSWORD='999239' psql -h 127.0.0.1 -p 5432 -U odoo20 -d postgres -c "CREATE DATABASE odoo20 OWNER odoo20;"

PGPASSWORD='999239' pg_restore \
    -h 127.0.0.1 \
    -p 5432 \
    -U odoo20 \
    -d odoo20 \
    --clean \
    --if-exists \
    "${BACKUP_PATH}/odoo20.dump"

sudo -u odoo20 rsync -a --delete "${BACKUP_PATH}/filestore/" /home/odoo20/odoo20/filestore/
sudo -u odoo20 rsync -a "${BACKUP_PATH}/custom_addons/" /home/odoo20/odoo20/custom_addons/
sudo cp "${BACKUP_PATH}/odoo.conf" /home/odoo20/odoo20/odoo.conf

sudo chown -R odoo20:odoo20 /home/odoo20/odoo20

sudo systemctl start odoo20
```

### 29.3 Database-Only Backup

```bash
PGPASSWORD='999239' pg_dump \
    -h 127.0.0.1 \
    -p 5432 \
    -U odoo20 \
    -Fc \
    odoo20 > /home/odoo20/odoo20/backups/odoo20_db_only.dump
```

### 29.4 Database-Only Restore

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 5432 -U odoo20 -d postgres -c "DROP DATABASE IF EXISTS odoo20;"
PGPASSWORD='999239' psql -h 127.0.0.1 -p 5432 -U odoo20 -d postgres -c "CREATE DATABASE odoo20 OWNER odoo20;"

PGPASSWORD='999239' pg_restore \
    -h 127.0.0.1 \
    -p 5432 \
    -U odoo20 \
    -d odoo20 \
    --clean \
    --if-exists \
    /home/odoo20/odoo20/backups/odoo20_db_only.dump
```

---

## 30. Log Rotation

Install logrotate if missing.

```bash
sudo apt install -y logrotate
```

Create fixed log rotation for Odoo.

```bash
sudo tee /etc/logrotate.d/odoo20 > /dev/null <<'EOF'
/home/odoo20/odoo20/logs/odoo.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 odoo20 odoo20
    sharedscripts
    postrotate
        systemctl kill -s USR2 odoo20.service || true
    endscript
}
EOF
```

Test:

```bash
sudo logrotate -d /etc/logrotate.d/odoo20
```

---

## 31. Troubleshooting

### 31.1 Odoo Returns 502 Through Nginx

Check Odoo:

```bash
sudo systemctl status odoo20 --no-pager
sudo journalctl -u odoo20 -n 100 --no-pager
```

Check ports:

```bash
sudo ss -ltnp | grep -E ':(8020|8072)'
```

Check Nginx error log:

```bash
sudo tail -n 100 /var/log/nginx/error.log
```

Common causes:

- Odoo is not running.
- Wrong `http_port`.
- Wrong `gevent_port`.
- Firewall blocking local ports.
- PostgreSQL/PgBouncer unavailable.

### 31.2 Odoo Cannot Connect to PostgreSQL Through PgBouncer

Test direct PostgreSQL:

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 5432 -U odoo20 -d postgres -c "SELECT 1;"
```

Test PgBouncer:

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d postgres -c "SELECT 1;"
```

Check PgBouncer log:

```bash
sudo journalctl -u pgbouncer -n 100 --no-pager
```

Common causes:

- Wrong SCRAM secret in `/etc/pgbouncer/userlist.txt`.
- PostgreSQL user password changed after PgBouncer userlist was generated.
- `pg_hba.conf` does not allow SCRAM-SHA-256.
- PgBouncer is not running.

Rebuild PgBouncer userlist:

```bash
SCRAM_SECRET=$(sudo -u postgres psql -Atc "SELECT rolpassword FROM pg_authid WHERE rolname='odoo20';")

printf '"odoo20" "%s"\n' "$SCRAM_SECRET" | \
    sudo tee /etc/pgbouncer/userlist.txt > /dev/null

sudo chown pgbouncer:pgbouncer /etc/pgbouncer/userlist.txt
sudo chmod 600 /etc/pgbouncer/userlist.txt

sudo systemctl restart pgbouncer
```

### 31.3 Persian Interface Does Not Appear RTL

Check language direction:

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 -c \
"SELECT code, name, direction FROM res_lang WHERE code = 'fa_IR';"
```

Expected:

```
 direction
-----------
 rtl
```

If not:

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 -c \
"UPDATE res_lang SET direction = 'rtl' WHERE code = 'fa_IR';"
```

Regenerate assets:

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate
./odoo-bin -c odoo.conf -d odoo20 -u base,web --stop-after-init
EOS

sudo systemctl start odoo20
```

Clear browser cache.

### 31.4 Persian Characters Appear as Boxes in PDF

Check fonts:

```bash
fc-match "Vazirmatn"
fc-match "Noto Naskh Arabic"
fc-match "KacstOne"
```

Rebuild font cache:

```bash
sudo fc-cache -fv
```

Check `wkhtmltopdf`:

```bash
wkhtmltopdf --version
```

Ensure it is patched.

Restart Odoo:

```bash
sudo systemctl restart odoo20
```

### 31.5 Persian Text Is Disconnected or Rendered Incorrectly in PDF

This usually means `wkhtmltopdf` is not patched or fonts are missing.

Reinstall patched `wkhtmltopdf`:

```bash
sudo apt remove -y wkhtmltopdf wkhtmltox || true

install_wkhtmltopdf() {
    BASE_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3"

    for codename in noble jammy bionic; do
        PKG="wkhtmltox_0.12.6.1-3.${codename}_amd64.deb"

        if curl -fsIL "${BASE_URL}/${PKG}" > /dev/null; then
            wget "${BASE_URL}/${PKG}"
            sudo dpkg -i "${PKG}" || true
            sudo apt --fix-broken install -y
            rm -f "${PKG}"
            return 0
        fi
    done

    return 1
}

install_wkhtmltopdf

sudo fc-cache -fv
sudo systemctl restart odoo20
```

### 31.6 WebSocket or Chat Does Not Work

Check port 8072:

```bash
sudo ss -ltnp | grep 8072
```

Check Nginx upstream:

```bash
sudo nginx -T | grep -A 5 "upstream odoochat"
```

Check Odoo log:

```bash
sudo journalctl -u odoo20 -n 100 --no-pager
```

Ensure `gevent_port = 8072` exists in:

```
/home/odoo20/odoo20/odoo.conf
```

Restart Odoo:

```bash
sudo systemctl restart odoo20
```

### 31.7 New Custom Addon Does Not Appear in Apps

Ensure the addon path is included:

```
addons_path = /home/odoo20/odoo20/odoo/addons,/home/odoo20/odoo20/addons,/home/odoo20/odoo20/custom_addons
```

Ensure the addon folder contains:

```
__manifest__.py
```

Ensure the manifest has:

```python
'installable': True,
'application': True,
```

Restart Odoo and update apps list:

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate
./odoo-bin -c odoo.conf -d odoo20 -u base --stop-after-init
EOS

sudo systemctl start odoo20
```

Then in UI:

```
Apps → Update Apps List
```

### 31.8 Permission Errors on Filestore or Logs

Fix permissions:

```bash
sudo chown -R odoo20:odoo20 /home/odoo20/odoo20
sudo chmod -R u+rwX /home/odoo20/odoo20/filestore
sudo chmod -R u+rwX /home/odoo20/odoo20/logs
sudo chmod 755 /home/odoo20/odoo20/custom_addons
```

Restart Odoo:

```bash
sudo systemctl restart odoo20
```

### 31.9 PostgreSQL Extension Missing Inside Odoo Database

Enable extensions manually:

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 -c \
"CREATE EXTENSION IF NOT EXISTS vector;
 CREATE EXTENSION IF NOT EXISTS pg_trgm;
 CREATE EXTENSION IF NOT EXISTS unaccent;
 CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
```

Restart Odoo:

```bash
sudo systemctl restart odoo20
```

### 31.10 Cloudflare Quick Tunnel Drops or Fails

- Check `cloudflared` output for errors.
- Verify Nginx is running: `sudo systemctl status nginx`
- Ensure the tunnel command points to `https://localhost:443` with `--no-tls-verify`.
- Quick Tunnel URLs change on every restart — this is expected.
- If you see 429, you hit the 200 in-flight request limit. Wait and retry.

### 31.11 CSRF / Session Errors Behind Cloudflare

Ensure `X-Forwarded-Host` is set in Nginx and `proxy_mode = True` in `odoo.conf`.

### 31.12 Camera Does Not Work on Mobile

- Confirm the URL starts with `https://`.
- Confirm browser permission for camera is granted.
- On iOS Safari: **Settings → Safari → Camera → Ask or Allow**.
- On Android Chrome: tap the lock icon → **Permissions → Camera → Allow**.
- Confirm Odoo is loaded over HTTPS end-to-end (Cloudflare Tunnel → Nginx SSL → Odoo with `proxy_mode = True`).

---

## 32. Final Verification Checklist

Run these checks after installation.

### 32.1 Services

```bash
sudo systemctl status postgresql --no-pager
sudo systemctl status pgbouncer --no-pager
sudo systemctl status redis-server --no-pager
sudo systemctl status nginx --no-pager
sudo systemctl status odoo20 --no-pager
```

All should be active.

### 32.2 Ports

```bash
sudo ss -ltnp | grep -E ':(80|443|6432|8020|8072|5432|6379)\b'
```

Expected:

| Port | Service |
|---|---|
| 80 | Nginx HTTP |
| 443 | Nginx HTTPS |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 6432 | PgBouncer |
| 8020 | Odoo HTTP |
| 8072 | Odoo evented/WebSocket/longpolling |

### 32.3 PostgreSQL Direct Connection

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 5432 -U odoo20 -d postgres -c "SELECT version();"
```

### 32.4 PgBouncer Connection

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d postgres -c "SELECT 1;"
```

### 32.5 Odoo Database Extensions

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 -c \
"SELECT extname, extversion FROM pg_extension ORDER BY extname;"
```

Expected at least:

```
vector
pg_trgm
unaccent
pg_stat_statements
```

### 32.6 Persian Language Record

```bash
PGPASSWORD='999239' psql -h 127.0.0.1 -p 6432 -U odoo20 -d odoo20 -c \
"SELECT code, name, direction FROM res_lang WHERE code = 'fa_IR';"
```

Expected direction:

```
rtl
```

### 32.7 Redis

```bash
redis-cli ping
```

Expected:

```
PONG
```

### 32.8 Nginx HTTPS Test

```bash
curl -k -I https://127.0.0.1
```

Expected:

```
HTTP/1.1 303 SEE OTHER
```

or another valid Odoo HTTP response.

### 32.9 wkhtmltopdf

```bash
wkhtmltopdf --version
```

Expected:

```
wkhtmltopdf 0.12.6
...
with patched qt
```

### 32.10 RTL Tooling

```bash
node -v
npm -v
rtlcss --version || true
```

### 32.11 Persian Fonts

```bash
fc-match "Vazirmatn"
fc-match "Noto Naskh Arabic"
fc-match "KacstOne"
```

### 32.12 Odoo Log

```bash
sudo tail -n 100 /home/odoo20/odoo20/logs/odoo.log
```

Look for:

```
Modules loaded
HTTP service (127.0.0.1:8020) running
```

or equivalent Odoo 20 startup messages.

### 32.13 Cloudflare Quick Tunnel

```bash
cloudflared tunnel --url https://localhost:443 --no-tls-verify
```

Open the printed `trycloudflare.com` URL on your phone and confirm:
- Odoo login page appears.
- You can log in as `admin`.
- A camera-enabled module works.

---

## Quick Daily Commands

### Start Odoo

```bash
sudo systemctl start odoo20
```

### Stop Odoo

```bash
sudo systemctl stop odoo20
```

### Restart Odoo

```bash
sudo systemctl restart odoo20
```

### Odoo Status

```bash
sudo systemctl status odoo20 --no-pager
```

### Follow Odoo Logs

```bash
sudo journalctl -u odoo20 -f
```

### Start Cloudflare Quick Tunnel

```bash
cloudflared tunnel --url https://localhost:443 --no-tls-verify
```

### Upgrade One Addon

```bash
sudo systemctl stop odoo20

sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20
source venv/bin/activate
./odoo-bin -c odoo.conf -d odoo20 -u new_addon --stop-after-init
EOS

sudo systemctl start odoo20
```

### Update All Independent Addon Git Repositories

```bash
sudo -iu odoo20 bash -s <<'EOS'
cd /home/odoo20/odoo20/custom_addons

for addon_dir in */; do
    if [ -d "${addon_dir}/.git" ]; then
        echo "Updating: ${addon_dir}"
        git -C "${addon_dir}" fetch --all --prune
        git -C "${addon_dir}" pull --ff-only
    fi
done
EOS
```

### Full Manual Backup

```bash
sudo systemctl stop odoo20

BACKUP_DIR="/home/odoo20/odoo20/backups/manual_$(date +%Y%m%d_%H%M%S)"
sudo -u odoo20 mkdir -p "${BACKUP_DIR}"

PGPASSWORD='999239' pg_dump -h 127.0.0.1 -p 5432 -U odoo20 -Fc odoo20 > "${BACKUP_DIR}/odoo20.dump"

sudo -u odoo20 rsync -a /home/odoo20/odoo20/filestore "${BACKUP_DIR}/filestore"
sudo -u odoo20 rsync -a /home/odoo20/odoo20/custom_addons "${BACKUP_DIR}/custom_addons"
sudo -u odoo20 cp /home/odoo20/odoo20/odoo.conf "${BACKUP_DIR}/odoo.conf"

sudo chown -R odoo20:odoo20 "${BACKUP_DIR}"

sudo systemctl start odoo20

echo "Backup created at: ${BACKUP_DIR}"
```

---

## Summary of All Configuration Files

| File | Purpose |
|---|---|
| `/etc/sysctl.d/99-odoo20-performance.conf` | OS kernel and system limits tuning |
| `/etc/security/limits.d/99-odoo20.conf` | User limits for `odoo20` and `postgres` |
| `/etc/postgresql/17/main/conf.d/99-odoo20-performance.conf` | PostgreSQL 17 tuning for 32 GB RAM |
| `/etc/postgresql/17/main/pg_hba.conf` | PostgreSQL authentication rules |
| `/etc/pgbouncer/pgbouncer.ini` | PgBouncer connection pooling (session mode) |
| `/etc/pgbouncer/userlist.txt` | PgBouncer authentication |
| `/etc/redis/redis.conf` | Redis cache/session tuning |
| `/home/odoo20/odoo20/odoo.conf` | Odoo main configuration |
| `/etc/systemd/system/odoo20.service` | Odoo systemd service |
| `/etc/nginx/nginx.conf` | Nginx main configuration |
| `/etc/nginx/sites-available/odoo20` | Nginx reverse proxy with SSL |
| `/etc/nginx/ssl/odoo20.crt` + `.key` | Self-signed SSL certificate |
| `/home/odoo20/odoo20/.gitignore` | Parent repo ignore rules for sub-Git addons |
| `/etc/logrotate.d/odoo20` | Odoo log rotation |

---

This guide provides a complete, fixed deployment profile for **Odoo 20** on **Kubuntu 26 / Ubuntu LTS** with **32 GB RAM**, including **PgBouncer**, **Redis**, **pgvector** for AI, **self-signed SSL**, **Cloudflare Quick Tunnel (free, no domain required)**, full **Persian RTL support**, and **mobile camera testing over HTTPS**. All configuration files are included inline.

