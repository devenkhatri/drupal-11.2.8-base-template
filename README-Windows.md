# Drupal 11.2.8 Docker Development Environment - Windows Guide

This document provides a complete Docker Compose setup for Drupal 11.2.8 with all required dependencies for local development on Windows systems.

## Prerequisites

- **Docker Desktop for Windows** (version 4.0 or later) - [Download](https://www.docker.com/products/docker-desktop)
  - Ensure WSL 2 (Windows Subsystem for Linux 2) backend is enabled
  - Or Hyper-V backend if you don't have WSL 2
- **Minimum 4GB RAM** allocated to Docker Desktop
- **Ports 80, 443, 3306, 8080, 1025, 8025** available
- **Git Bash** or **PowerShell** (recommended for command execution)
- **Text Editor** (VS Code, Sublime Text, or Notepad++)

## Important: Windows-Specific Setup

### 1. Enable WSL 2 or Hyper-V

**Option A: WSL 2 (Recommended)**
```powershell
# Open PowerShell as Administrator and run:
wsl --install
wsl --set-default-version 2

# After restart, verify WSL is running:
wsl --list --verbose
```

**Option B: Hyper-V**
```powershell
# Open PowerShell as Administrator and run:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Restart your computer when prompted
```

### 2. Configure Docker Desktop

1. **Open Docker Desktop Settings** (right-click Docker icon → Settings)
2. **Resources tab:**
   - Set CPUs: At least 2
   - Set Memory: At least 4GB (6-8GB recommended)
   - Set Disk image size: At least 50GB
3. **General tab:**
   - ✓ Start Docker Desktop when you log in
   - ✓ Use WSL 2 based engine (if available)
4. **File Sharing tab:**
   - Add your project directory (e.g., `C:\Users\YourUsername\Projects`)

### 3. Line Endings Configuration

Windows uses different line endings (CRLF) than Linux (LF). This can cause issues in Docker containers.

**Configure Git to handle line endings:**
```powershell
# Open PowerShell and run:
git config --global core.autocrlf input
```

This ensures scripts in Docker containers work properly.

## System Requirements

Based on Drupal 11.2 requirements:

- **PHP**: 8.3 or newer
- **Database**: MariaDB 10.6+ or MySQL 8.0+
- **Composer**: 2.7.7+

## Check for Port Conflicts

If any of the default ports are not available on your Windows machine, you can add custom ports in the `.env` file (see steps below).

### For Windows Command Prompt

```cmd
netstat -ano | findstr :80
netstat -ano | findstr :443
netstat -ano | findstr :8080
netstat -ano | findstr :3306
netstat -ano | findstr :1025
netstat -ano | findstr :8025
```

### For Windows PowerShell

```powershell
# Check individual ports
netstat -ano | findstr ":80"
netstat -ano | findstr ":443"
netstat -ano | findstr ":8080"
netstat -ano | findstr ":3306"
netstat -ano | findstr ":1025"
netstat -ano | findstr ":8025"

# Or use this script to check all ports at once:
$ports = @(80, 443, 8080, 3306, 1025, 8025)
foreach ($port in $ports) {
    $result = netstat -ano | findstr ":$port"
    if ($result) {
        Write-Host "Port $port is in use: $result"
    } else {
        Write-Host "Port $port is available"
    }
}
```

### To find and kill the process using a port:

```powershell
# Find process ID using port 80
netstat -ano | findstr ":80"

# Kill the process (replace PID with the actual process ID)
taskkill /PID <PID> /F

# Example:
taskkill /PID 1234 /F
```

---

## Project Directory Setup

### Create Project Structure

Open **PowerShell** or **Git Bash** and run:

```powershell
# Navigate to your desired location
cd C:\Users\YourUsername\Projects

# Create project directory
mkdir drupal-docker
cd drupal-docker

# Create configuration and log directories
mkdir config\php
mkdir config\nginx
mkdir config\cron
mkdir logs\nginx
mkdir mariadb-init
mkdir drupal

# Verify structure
tree /F
# Or in PowerShell:
Get-ChildItem -Recurse -Force | Format-Wide
```

---

## Docker Compose Configuration

### Main docker-compose.yml

Create a file named `docker-compose.yml` in your project root:

```yaml
version: '3.8'

services:
  # Traefik Reverse Proxy
  traefik:
    image: traefik:v2.10
    container_name: drupal_traefik
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-843}:443"
      - "${TRAEFIK_DASHBOARD_PORT:-8080}:8080"  # Traefik dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/certs:/certs
    networks:
      - drupal_network
    restart: unless-stopped

  # MariaDB Database
  mariadb:
    image: mariadb:10.11
    ports:
      - "${MARIADB_PORT:-3306}:3306"
    container_name: drupal_mariadb
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: drupal
      MYSQL_USER: drupal
      MYSQL_PASSWORD: drupal
    volumes:
      - mariadb_data:/var/lib/mysql
      - ./mariadb-init:/docker-entrypoint-initdb.d
    networks:
      - drupal_network
    restart: unless-stopped
    command: 
      - --max_allowed_packet=256M
      - --innodb_buffer_pool_size=512M
      - --innodb_log_file_size=128M

  # PHP-FPM 8.3
  php:
    image: drupal:11.2.8-php8.3-fpm-alpine
    container_name: drupal_php
    volumes:
      - ./drupal:/opt/drupal
      - ./config/php/php.ini:/usr/local/etc/php/conf.d/custom.ini
      - ./config/php/php-fpm.conf:/usr/local/etc/php-fpm.d/zz-custom.conf
    environment:
      PHP_MEMORY_LIMIT: 512M
      PHP_MAX_EXECUTION_TIME: 300
      PHP_UPLOAD_MAX_FILESIZE: 256M
      PHP_POST_MAX_SIZE: 256M
    networks:
      - drupal_network
    depends_on:
      - mariadb
    restart: unless-stopped

  # Nginx Web Server
  nginx:
    image: nginx:1.25-alpine
    container_name: drupal_nginx
    volumes:
      - ./drupal:/opt/drupal
      - ./config/nginx/default.conf:/etc/nginx/conf.d/default.conf
      - ./logs/nginx:/var/log/nginx
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.drupal.rule=Host(`drupal.localhost`)"
      - "traefik.http.routers.drupal.entrypoints=web"
      - "traefik.http.services.drupal.loadbalancer.server.port=80"
    networks:
      - drupal_network
    depends_on:
      - php
    restart: unless-stopped

  # Drupal (for initial installation and drush)
  drupal:
    image: drupal:11.2.8-php8.3-fpm-alpine
    container_name: drupal_app
    volumes:
      - ./drupal:/opt/drupal
      - ./config/php/php.ini:/usr/local/etc/php/conf.d/custom.ini
    environment:
      DRUPAL_DATABASE_HOST: mariadb
      DRUPAL_DATABASE_PORT: 3306
      DRUPAL_DATABASE_NAME: drupal
      DRUPAL_DATABASE_USERNAME: drupal
      DRUPAL_DATABASE_PASSWORD: drupal
    networks:
      - drupal_network
    depends_on:
      - mariadb
    restart: unless-stopped
    command: ["tail", "-f", "/dev/null"]  # Keep container running

  # phpMyAdmin
  phpmyadmin:
    image: phpmyadmin:5.2
    ports:
      - "${PHPMYADMIN_DIRECT_PORT:-80}:80"
    container_name: drupal_phpmyadmin
    environment:
      PMA_HOST: mariadb
      PMA_PORT: 3306
      PMA_USER: drupal
      PMA_PASSWORD: drupal
      UPLOAD_LIMIT: 256M
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.phpmyadmin.rule=Host(`pma.localhost`)"
      - "traefik.http.routers.phpmyadmin.entrypoints=web"
      - "traefik.http.services.phpmyadmin.loadbalancer.server.port=80"
    networks:
      - drupal_network
    depends_on:
      - mariadb
    restart: unless-stopped

  # Mailhog (Mail catcher for development)
  mailhog:
    image: mailhog/mailhog:latest
    container_name: drupal_mailhog
    ports:
      - "${MAILHOG_SMTP_PORT:-1025}:1025"  # SMTP server
      - "${MAILHOG_WEB_PORT:-8025}:8025"  # Web UI
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mailhog.rule=Host(`mail.localhost`)"
      - "traefik.http.routers.mailhog.entrypoints=web"
      - "traefik.http.services.mailhog.loadbalancer.server.port=8025"
    networks:
      - drupal_network
    restart: unless-stopped

  # Cron service
  cron:
    image: drupal:11.2.8-php8.3-fpm-alpine
    container_name: drupal_cron
    volumes:
      - ./drupal:/opt/drupal
      - ./config/cron/drupal-cron:/etc/cron.d/drupal-cron
    networks:
      - drupal_network
    depends_on:
      - mariadb
      - php
    restart: unless-stopped
    command: crond -f -l 2

  # Drush CLI container
  drush:
    image: drupal:11.2.8-php8.3-fpm-alpine
    container_name: drupal_drush
    volumes:
      - ./drupal:/opt/drupal
    working_dir: /opt/drupal
    networks:
      - drupal_network
    depends_on:
      - mariadb
    restart: "no"
    entrypoint: ["/bin/sh"]
    profiles:
      - tools

networks:
  drupal_network:
    driver: bridge

volumes:
  mariadb_data:
    driver: local
```

---

## Configuration Files

### 1. PHP Configuration (config/php/php.ini)

Create `config\php\php.ini`:

```ini
; PHP Configuration for Drupal 11
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
upload_max_filesize = 256M
post_max_size = 256M
max_input_vars = 5000

; Error reporting (development)
display_errors = On
display_startup_errors = On
error_reporting = E_ALL

; Date and timezone
date.timezone = Asia/Kolkata

; OPcache settings
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 0
opcache.validate_timestamps = 1
opcache.fast_shutdown = 1

; Session settings
session.cookie_lifetime = 0
session.gc_maxlifetime = 86400
```

### 2. PHP-FPM Configuration (config/php/php-fpm.conf)

Create `config\php\php-fpm.conf`:

```ini
; PHP-FPM Configuration for Drupal
[www]
listen = 0.0.0.0:9000
listen.allowed_clients = 127.0.0.1

; Process manager settings
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

; Environment settings
env[DRUPAL_ENV] = development

; Logging
access.log = /var/log/php-fpm/access.log
slowlog = /var/log/php-fpm/slow.log
request_slowlog_timeout = 10s
```

### 3. Nginx Configuration (config/nginx/default.conf)

Create `config\nginx\default.conf`:

```nginx
server {
    listen 80;
    server_name drupal.localhost;
    root /opt/drupal/web;
    index index.php index.html index.htm;

    # Logging
    access_log /var/log/nginx/drupal_access.log;
    error_log /var/log/nginx/drupal_error.log;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Handle requests
    location / {
        # Try to serve files directly, fallback to front controller
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP-FPM configuration
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DRUPAL_ENV development;
        
        # Timeouts
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
    }

    # Deny access to files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to hidden files
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Drupal files directory
    location ~* ^/sites/default/files/ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 4. Cron Configuration (config/cron/drupal-cron)

Create `config\cron\drupal-cron`:

```cron
# Drupal 11 Cron Job
# Runs every 6 hours
0 */6 * * * cd /opt/drupal && /usr/local/bin/php web/core/scripts/cron.php >> /var/log/cron.log 2>&1
```

### 5. MariaDB Initialization Script (mariadb-init/init.sql)

Create `mariadb-init\init.sql`:

```sql
-- Drupal 11 MariaDB Initialization
-- This file runs automatically when the database container starts

-- Ensure UTF-8 character set
ALTER DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create additional databases if needed for multi-site setup
-- CREATE DATABASE drupal_site2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Additional system variables
SET GLOBAL max_connections = 1000;
SET GLOBAL wait_timeout = 600;
SET GLOBAL interactive_timeout = 600;
```

### 6. Environment Configuration (.env)

Create `.env` in your project root to override default port configurations:

```env
# Port Configuration
HTTP_PORT=80
HTTPS_PORT=843
TRAEFIK_DASHBOARD_PORT=8080
MARIADB_PORT=3306
PHPMYADMIN_DIRECT_PORT=8081
MAILHOG_SMTP_PORT=1025
MAILHOG_WEB_PORT=8025

# Database Configuration
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal

# PHP Configuration
PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300
PHP_UPLOAD_MAX_FILESIZE=256M
PHP_POST_MAX_SIZE=256M
```

---

## Getting Started with Docker Compose

### Windows PowerShell Commands

Open **PowerShell** in your project directory and execute the following commands:

#### 1. Start Docker Containers

```powershell
# Build and start all services
docker-compose up -d

# View the status
docker-compose ps

# Check logs (real-time)
docker-compose logs -f

# View specific service logs
docker-compose logs drupal
docker-compose logs php
docker-compose logs mariadb
```

#### 2. Install Drupal

```powershell
# Install Drupal using Composer (inside the drupal container)
docker-compose exec drupal bash -c "cd /opt/drupal && composer install --no-dev"

# Check Drupal installation status
docker-compose exec drupal ls -la /opt/drupal/web/

# Create Drupal files directory
docker-compose exec drupal mkdir -p /opt/drupal/web/sites/default/files
docker-compose exec drupal chmod 775 /opt/drupal/web/sites/default/files

# Set up settings file
docker-compose exec drupal cp /opt/drupal/web/sites/default/default.settings.php /opt/drupal/web/sites/default/settings.php
docker-compose exec drupal chmod 644 /opt/drupal/web/sites/default/settings.php
```

#### 3. Configure Hosts File (for drupal.localhost access)

You need to add entries to your Windows hosts file:

**Option A: Using PowerShell (Run as Administrator)**

```powershell
# Open PowerShell as Administrator and run:
Add-Content -Path "$env:windir\System32\drivers\etc\hosts" -Value "`n127.0.0.1 drupal.localhost"
Add-Content -Path "$env:windir\System32\drivers\etc\hosts" -Value "127.0.0.1 pma.localhost"
Add-Content -Path "$env:windir\System32\drivers\etc\hosts" -Value "127.0.0.1 mail.localhost"
Add-Content -Path "$env:windir\System32\drivers\etc\hosts" -Value "127.0.0.1 localhost"

# Verify entries were added
Select-String -Path "$env:windir\System32\drivers\etc\hosts" -Pattern "drupal.localhost"
```

**Option B: Manual Edit**

1. Open **Notepad** as Administrator
2. Go to **File → Open** and navigate to `C:\Windows\System32\drivers\etc\hosts`
3. Add the following lines at the end:
   ```
   127.0.0.1 drupal.localhost
   127.0.0.1 pma.localhost
   127.0.0.1 mail.localhost
   ```
4. Save the file

#### 4. Run Drush Commands

```powershell
# Using docker-compose with drush profile
docker-compose run --rm drush drush help

# Check Drupal status
docker-compose run --rm drush drush status

# Run database updates
docker-compose run --rm drush drush updatedb

# Clear caches
docker-compose run --rm drush drush cr
```

#### 5. Execute PHP Commands

```powershell
# Run PHP commands in the Drupal container
docker-compose exec drupal php -v

# Run custom PHP scripts
docker-compose exec drupal php /opt/drupal/web/index.php

# Access PHP interactive shell
docker-compose exec drupal php -a
```

#### 6. Database Operations

```powershell
# Access MariaDB CLI
docker-compose exec mariadb mysql -u drupal -pdrupal -h mariadb -D drupal

# Backup database
docker-compose exec mariadb mysqldump -u drupal -pdrupal drupal > backup.sql

# Restore database
docker-compose exec -T mariadb mysql -u drupal -pdrupal drupal < backup.sql

# Check database size
docker-compose exec mariadb mysql -u drupal -pdrupal -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb FROM information_schema.tables WHERE table_schema = 'drupal' ORDER BY size_mb DESC;"
```

#### 7. Stop and Clean Up

```powershell
# Stop all containers (data persists)
docker-compose stop

# Start containers again
docker-compose start

# Stop and remove containers (data persists in volumes)
docker-compose down

# Stop and remove everything including volumes (WARNING: deletes data!)
docker-compose down -v

# View logs before shutdown
docker-compose logs > logs.txt
```

---

## Verify Installation

This section ensures all components are working correctly before proceeding with Drupal configuration.

### 1. Verify Docker Containers (PowerShell)

Check that all containers are running and healthy:

```powershell
docker-compose ps
```

**Expected output:**
```
NAME                 COMMAND                  SERVICE        STATUS      PORTS
drupal_traefik       "traefik --api.insec…"   traefik        Up 2 min    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8080->8080/tcp
drupal_mariadb       "docker-entrypoint.s…"   mariadb        Up 2 min    3306/tcp
drupal_php           "docker-php-entrypoi…"   php            Up 2 min    9000/tcp
drupal_nginx         "nginx -g daemon off;…"  nginx          Up 2 min    80/tcp
drupal_app           "tail -f /dev/null"      drupal         Up 2 min
drupal_phpmyadmin    "/docker-entrypoint.…"   phpmyadmin     Up 1 min    80/tcp
drupal_mailhog       "MailHog"                mailhog        Up 1 min    0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
drupal_cron          "crond -f -l 2"          cron           Up 1 min
```

All containers should show **Up** status.

### 2. Verify Database Connection (PowerShell)

Test that the database is accessible and configured correctly:

```powershell
# Connect to MySQL and check database
docker-compose exec mariadb mysql -u drupal -pdrupal -h mariadb -e "SHOW DATABASES; SELECT DATABASE(); SELECT USER();"
```

**Expected output:**
```
+--------------------+
| Database           |
+--------------------+
| drupal             |
| information_schema |
+--------------------+
DATABASE()
drupal
USER()
drupal@drupal_mariadb
```

### 3. Verify Drupal Files Structure (PowerShell)

Confirm that Drupal is properly installed in the container:

```powershell
# Check Drupal directory structure
docker-compose exec drupal ls -la /opt/drupal/

# Verify key directories exist
docker-compose exec drupal test -d /opt/drupal/web && Write-Host "✓ web directory exists"
docker-compose exec drupal test -d /opt/drupal/vendor && Write-Host "✓ vendor directory exists"
docker-compose exec drupal test -f /opt/drupal/composer.json && Write-Host "✓ composer.json exists"
```

**Expected output:**
```
✓ web directory exists
✓ vendor directory exists
✓ composer.json exists
```

### 4. Verify Composer.json Validity (PowerShell)

Ensure the composer.json file is valid JSON and contains Drupal configuration:

```powershell
# Check composer.json validity
docker-compose exec drupal cat /opt/drupal/composer.json | Select-Object -First 30

# Verify it's valid JSON
docker-compose exec drupal php -r "json_decode(file_get_contents('/opt/drupal/composer.json')); echo 'JSON is valid';"
```

**Expected output - JSON is valid**

### 5. Verify PHP-FPM Connection (PowerShell)

Test that Nginx can communicate with PHP-FPM:

```powershell
# Check PHP version
docker-compose exec php php -v

# Check PHP extensions
docker-compose exec php php -m | Where-Object { $_ -match "(pdo|mysql|gd|curl|json)" }
```

**Expected output should include:**
- PDO
- pdo_mysql
- gd
- curl
- json

### 6. Verify Nginx Configuration (PowerShell)

Ensure Nginx is properly configured to serve Drupal:

```powershell
# Test Nginx configuration
docker-compose exec nginx nginx -t

# Check access to Drupal
Invoke-WebRequest -Uri "http://localhost/index.php" -UseBasicParsing
```

**Expected output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 7. Verify Traefik Routing (PowerShell)

Check that Traefik is properly routing to all services:

```powershell
# Access Traefik API to view routers
Invoke-RestMethod -Uri "http://localhost:8080/api/http/routers"

# Check if drupal.localhost route exists
Invoke-RestMethod -Uri "http://localhost:8080/api/http/routers" | Where-Object { $_ -match "drupal" }
```

Should see routing configuration for drupal, phpmyadmin, and mailhog services.

### 8. Verify File Permissions (PowerShell)

Ensure Drupal files have correct ownership and permissions:

```powershell
# Check file ownership
docker-compose exec drupal ls -l /opt/drupal/web/sites/default/files

# Verify www-data ownership
docker-compose exec drupal stat -c '%U:%G' /opt/drupal/web/sites/default
```

**Expected output:**
```
www-data:www-data
```

### 9. Verify Services Accessibility (PowerShell)

Test that all services are accessible via their routes:

```powershell
# Drupal
Invoke-WebRequest -Uri "http://drupal.localhost/" -UseBasicParsing
# Expected: 200 or 302 response

# phpMyAdmin
Invoke-WebRequest -Uri "http://pma.localhost/" -UseBasicParsing
# Expected: 200 response

# Mailhog
Invoke-WebRequest -Uri "http://mail.localhost/" -UseBasicParsing
# Expected: 200 response

# Traefik Dashboard
Invoke-WebRequest -Uri "http://localhost:8080/dashboard/" -UseBasicParsing
# Expected: 200 response
```

### 10. Verify Complete Health Check Script (PowerShell)

Run this comprehensive verification script:

```powershell
# Create a verification script
docker-compose exec drupal bash << 'EOF'
echo "=== DRUPAL DOCKER ENVIRONMENT VERIFICATION ==="
echo ""

echo "1. Checking container communication..."
php -r "echo '[✓] PHP is working' . PHP_EOL;"

echo "2. Checking database connection..."
php -r "
try {
    \$pdo = new PDO('mysql:host=mariadb;dbname=drupal', 'drupal', 'drupal');
    echo '[✓] Database connection successful' . PHP_EOL;
} catch (Exception \$e) {
    echo '[✗] Database connection failed: ' . \$e->getMessage() . PHP_EOL;
}
"

echo "3. Checking Drupal files..."
test -f /opt/drupal/web/index.php && echo "[✓] Drupal index.php found" || echo "[✗] index.php missing"
test -f /opt/drupal/composer.json && echo "[✓] composer.json found" || echo "[✗] composer.json missing"

echo "4. Checking PHP version..."
php -v | head -1

echo "5. Checking required PHP extensions..."
php -m | grep -q pdo_mysql && echo "[✓] pdo_mysql enabled" || echo "[✗] pdo_mysql missing"
php -m | grep -q gd && echo "[✓] gd enabled" || echo "[✗] gd missing"
php -m | grep -q curl && echo "[✓] curl enabled" || echo "[✗] curl missing"

echo "6. Checking PHP memory limit..."
php -i | grep "memory_limit"

echo "7. Checking Drupal installation..."
test -d /opt/drupal/web/core && echo "[✓] Drupal core found" || echo "[✗] Drupal core not found"

echo ""
echo "=== VERIFICATION COMPLETE ==="
EOF
```

**Expected output:**
```
=== DRUPAL DOCKER ENVIRONMENT VERIFICATION ===

1. Checking container communication...
[✓] PHP is working
2. Checking database connection...
[✓] Database connection successful
3. Checking Drupal files...
[✓] Drupal index.php found
[✓] composer.json found
4. Checking PHP version...
PHP 8.3.x (cli) ...
5. Checking required PHP extensions...
[✓] pdo_mysql enabled
[✓] gd enabled
[✓] curl enabled
6. Checking PHP memory limit...
memory_limit = 512M
7. Checking Drupal installation...
[✓] Drupal core found

=== VERIFICATION COMPLETE ===
```

### 11. Web Browser Verification

Once all checks pass, verify via web browser:

1. **Navigate to Drupal**: Open `http://drupal.localhost` in your browser
   - You should see either:
     - Drupal installation wizard (if not installed yet)
     - Drupal homepage (if already installed)

2. **Check phpMyAdmin**: Open `http://pma.localhost`
   - Login with:
     - **Username**: drupal
     - **Password**: drupal
   - Verify the drupal database and tables exist

3. **Check Mailhog**: Open `http://mail.localhost` or `http://localhost:8025`
   - You should see the Mailhog web interface
   - No emails yet (unless you've sent test emails)

4. **Check Traefik Dashboard**: Open `http://localhost:8080`
   - Go to HTTP section
   - Verify routers for drupal, pma, and mail are listed
   - Check services are showing as Up

### 12. Troubleshooting Verification Issues (PowerShell)

**Issue: Container not starting**

```powershell
# Check container logs
docker-compose logs drupal
docker-compose logs php
docker-compose logs mariadb

# View all logs
docker-compose logs
```

**Issue: Database connection fails**

```powershell
# Verify MariaDB is running
docker-compose exec mariadb mysql -u root -proot -e "SELECT VERSION();"

# Check network connectivity
docker-compose exec php ping mariadb
```

**Issue: Port already in use**

```powershell
# Find process using the port (example: port 80)
netstat -ano | findstr ":80"

# Kill the process
taskkill /PID <PID> /F

# Alternatively, change port in docker-compose.yml or .env file
```

**Issue: Line ending problems (LF vs CRLF)**

```powershell
# Convert files to Unix line endings using PowerShell
Get-ChildItem -Path ./config -Include *.conf, *.ini, *.sql -Recurse | ForEach-Object {
    (Get-Content $_.FullName) -replace "`r`n", "`n" | Set-Content $_.FullName
}

# Or use Git (if installed)
git add --renormalize .
```

**Issue: Docker Desktop not starting**

1. Restart Docker Desktop:
   - Right-click Docker icon → **Quit Docker Desktop**
   - Wait 10 seconds
   - Open Docker Desktop again

2. Restart Windows

3. Check Docker Desktop logs:
   - Open **Event Viewer** → **Windows Logs** → **Application**
   - Look for Docker-related errors

**Issue: WSL 2 integration problems**

```powershell
# Update WSL 2 kernel
wsl --update

# List installed distributions
wsl --list -v

# Set default version to WSL 2
wsl --set-default-version 2
```

---

## Common Commands Reference

### Starting and Stopping Services (PowerShell)

```powershell
# Start services (detached mode)
docker-compose up -d

# Stop services (data persists)
docker-compose stop

# Restart services
docker-compose restart

# Rebuild and restart services
docker-compose up -d --build

# View all running containers
docker-compose ps

# View all containers including stopped
docker-compose ps -a

# Remove stopped containers
docker-compose rm -f

# View logs
docker-compose logs -f

# View specific container logs
docker-compose logs -f drupal

# View last N lines
docker-compose logs -f --tail=100 drupal
```

### Executing Commands in Containers (PowerShell)

```powershell
# Execute command in running container
docker-compose exec drupal <command>

# Example: Clear Drupal cache
docker-compose exec drupal drush cr

# Run command in new container (from profile)
docker-compose run --rm drush drush status

# Access container bash shell
docker-compose exec drupal /bin/bash

# Access container shell (ash for Alpine)
docker-compose exec drupal sh
```

### Managing Volumes (PowerShell)

```powershell
# List all volumes
docker volume ls

# View volume details
docker volume inspect <volume_name>

# View volume path on host
docker volume inspect drupal_mariadb_data

# Remove unused volumes
docker volume prune

# Backup volume
docker run --rm -v drupal_mariadb_data:/data -v ${PWD}:/backup busybox tar czf /backup/mariadb_backup.tar.gz /data

# Restore volume from backup
docker run --rm -v drupal_mariadb_data:/data -v ${PWD}:/backup busybox sh -c "cd /data && tar xzf /backup/mariadb_backup.tar.gz"
```

### Monitoring and Debugging (PowerShell)

```powershell
# Monitor resource usage
docker stats

# Inspect container details
docker inspect drupal_php

# View container processes
docker top drupal_php

# Check container network settings
docker network inspect drupal_drupal_network

# View Docker events in real-time
docker events

# Clean up unused resources
docker system prune

# View disk usage
docker system df
```

### Drupal-Specific Commands (PowerShell)

```powershell
# Clear all caches
docker-compose exec drupal drush cache-rebuild

# Update database
docker-compose exec drupal drush updatedb

# Enable module
docker-compose exec drupal drush module-install <module_name>

# Disable module
docker-compose exec drupal drush module-uninstall <module_name>

# List all modules
docker-compose exec drupal drush pm-list

# Export configuration
docker-compose exec drupal drush config-export

# Import configuration
docker-compose exec drupal drush config-import

# Generate one-time login link
docker-compose exec drupal drush user-login

# Set admin password
docker-compose exec drupal drush user-password admin --password=newpassword

# View watchdog logs
docker-compose exec drupal drush watchdog-show

# Clear watchdog logs
docker-compose exec drupal drush watchdog-delete all
```

---

## Important Windows-Specific Notes

### 1. Line Endings Issue

Windows uses CRLF (`\r\n`) line endings while Linux uses LF (`\n`). This can cause script execution issues in Docker containers.

**Solution: Configure Git**
```powershell
git config --global core.autocrlf input
```

### 2. File Path Separators

Use forward slashes (`/`) in Docker volume paths, not backslashes (`\`). Docker will handle the conversion automatically.

```yaml
# ✓ Correct
volumes:
  - ./drupal:/opt/drupal

# ✗ Incorrect - use forward slashes, not backslashes
# volumes:
#   - .\drupal:\opt\drupal
```

### 3. Mounting Paths

When using WSL 2, Docker Desktop automatically handles path conversion. You can reference Windows paths directly:

```powershell
# These both work in docker-compose.yml:
volumes:
  - ./drupal:/opt/drupal        # Relative path (recommended)
  - C:\\Users\\YourUser\\Projects\\drupal-docker\\drupal:/opt/drupal  # Absolute Windows path (Docker will convert)
```

### 4. Performance Considerations

For better performance on Windows:
- Keep Docker Desktop and WSL 2 updated
- Allocate sufficient RAM and CPU in Docker Desktop Settings
- Avoid mounting large directories across Windows/Linux boundary
- Use named volumes instead of bind mounts when possible

### 5. GPU Support

If your Windows machine has GPU and you want to use it:

```yaml
# Add to docker-compose.yml service definition
services:
  drupal:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

Requires: NVIDIA Docker runtime installed on Windows

### 6. Memory and CPU Limits

You can set resource limits for containers in docker-compose.yml:

```yaml
services:
  php:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### 7. Accessing Services from Windows Host

Services are accessible at:
- Drupal: `http://drupal.localhost` or `http://localhost`
- phpMyAdmin: `http://pma.localhost` or `http://localhost:8081`
- Mailhog: `http://mail.localhost` or `http://localhost:8025`
- Traefik Dashboard: `http://localhost:8080`

### 8. Firewall and Antivirus

If you have Windows Firewall or Antivirus enabled:
1. Ensure Docker Desktop is allowed through firewall
2. Disable real-time scanning for Docker directories if experiencing performance issues
3. Add Docker Desktop process to antivirus exclusion list if needed

### 9. Hyper-V Alternative to WSL 2

If WSL 2 is not available, Docker Desktop can use Hyper-V backend:
1. Open Docker Desktop Settings
2. General tab → uncheck "Use WSL 2 based engine"
3. Restart Docker Desktop
4. Hyper-V must be enabled (see Prerequisites section)

### 10. Working with PowerShell vs CMD

**PowerShell is recommended** because:
- Better for multi-line commands
- Better error messages
- Easier syntax for complex commands

When using **Command Prompt (CMD)**:
- Use `^` for line continuation instead of backtick
- Escape special characters differently
- Some commands may behave differently

---

## Backup and Restore

### Backup Everything

```powershell
# Create backup directory
mkdir backups

# Backup database
docker-compose exec mariadb mysqldump -u root -proot --all-databases > backups/full_backup.sql

# Backup Drupal files
Copy-Item -Path ./drupal -Destination ./backups/drupal_backup -Recurse

# Backup docker volumes
docker run --rm -v drupal_mariadb_data:/data -v ${PWD}/backups:/backup busybox tar czf /backup/mariadb_volume_backup.tar.gz /data

# Create backup archive
Compress-Archive -Path ./backups -DestinationPath "drupal_backup_$(Get-Date -Format 'yyyy-MM-dd').zip"
```

### Restore from Backup

```powershell
# Restore database
docker-compose exec -T mariadb mysql -u root -proot < backups/full_backup.sql

# Restore Drupal files
Remove-Item -Path ./drupal -Recurse -Force
Copy-Item -Path ./backups/drupal_backup -Destination ./drupal -Recurse

# Restore volume
docker volume rm drupal_mariadb_data
docker run --rm -v drupal_mariadb_data:/data -v ${PWD}/backups:/backup busybox sh -c "cd / && tar xzf /backup/mariadb_volume_backup.tar.gz"

# Restart containers
docker-compose restart
```

---

## Useful Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose Reference**: https://docs.docker.com/compose/compose-file/
- **Drupal 11 Documentation**: https://www.drupal.org/docs/drupal-apis/
- **Traefik Documentation**: https://doc.traefik.io/traefik/
- **MariaDB Documentation**: https://mariadb.com/docs/
- **Nginx Documentation**: https://nginx.org/en/docs/
- **PHP-FPM Documentation**: https://www.php.net/manual/en/install.fpm.php

---

## Support and Troubleshooting

For issues and questions:

1. **Check Container Logs**:
   ```powershell
   docker-compose logs -f
   ```

2. **Check Docker System Logs** (Windows Event Viewer):
   - Open Event Viewer
   - Navigate to Windows Logs → Application
   - Search for Docker-related entries

3. **Verify Docker Desktop Status**:
   - Right-click Docker icon
   - Check if Docker is running

4. **Restart Docker Desktop**:
   - Right-click Docker icon → Quit Docker Desktop
   - Wait 30 seconds
   - Restart Docker Desktop

5. **Check System Resources**:
   - Open Task Manager
   - Monitor CPU, Memory, and Disk usage
   - Allocate more resources to Docker if needed

6. **Consult Docker and Drupal Communities**:
   - Stack Overflow: Tag questions with `docker` and `drupal`
   - Drupal.org Forums: https://www.drupal.org/forum
   - Docker Community: https://www.docker.com/community

---

**Last Updated**: November 2025  
**Tested On**: Windows 10/11, Docker Desktop 4.x, WSL 2  
**Version**: Drupal 11.2.8 with PHP 8.3