# Drupal 11.2.8 Docker Development Environment

This document provides a complete Docker Compose setup for Drupal 11.2.8 with all required dependencies for local development.

## Prerequisites

- Docker Desktop installed and running
- Minimum 4GB RAM allocated to Docker
- Ports 80, 443, 3306, 8080, 1025, 8025 available

## System Requirements

Based on Drupal 11.2 requirements:

- **PHP**: 8.3 or newer
- **Database**: MariaDB 10.6+ or MySQL 8.0+
- **Composer**: 2.7.7+

## Check for Port Conflicts
If any of the default ports are not available on the server/machine then add custom ports in .env file as mentioned in below steps

### For Linux/Mac

```bash
lsof -i :80
lsof -i :443
lsof -i :8080
lsof -i :3306
lsof -i :1025
lsof -i :8025
```

Or all at once:

```bash
for port in 80 443 8080 3306 1025 8025; do
  lsof -i :$port && echo "Port $port in use";
done
```

### For Windows

```bash
netstat -ano | findstr :80
netstat -ano | findstr :443
netstat -ano | findstr :8080
netstat -ano | findstr :3306
netstat -ano | findstr :1025
netstat -ano | findstr :8025
```
---

## Docker Compose Configuration

### Main docker-compose.yml

Create a file named `docker-compose.yml` in your project root:
```
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
## Configuration Files

### 1. PHP Configuration (config/php/php.ini)

Create `config/php/php.ini`:
```
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

; Realpath cache
realpath_cache_size = 4096K
realpath_cache_ttl = 600
```
### 2. PHP-FPM Configuration (config/php/php-fpm.conf)

Create `config/php/php-fpm.conf`:
```
[www]
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500

; Logging
php_admin_value[error_log] = /var/log/fpm-php.www.log
php_admin_flag[log_errors] = on

; Security
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen
```
### 3. Nginx Configuration (config/nginx/default.conf)

Create `config/nginx/default.conf`:
```
server {
    listen 80;
    server_name drupal.localhost;
    root /opt/drupal/web;
    
    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
    
    # Logs
    access_log /var/log/nginx/drupal_access.log;
    error_log /var/log/nginx/drupal_error.log;
    
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Very rarely should these ever be accessed outside of your lan
    location ~* \.(txt|log)$ {
        deny all;
    }

    location ~ \..*/.*\.php$ {
        return 403;
    }

    location ~ ^/sites/.*/private/ {
        return 403;
    }

    # Block access to scripts in site files directory
    location ~ ^/sites/[^/]+/files/.*\.php$ {
        deny all;
    }

    # Allow "Well-Known URIs" as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }

    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\. {
        return 403;
    }

    location / {
        try_files $uri /index.php?$query_string;
    }

    location @rewrite {
        rewrite ^ /index.php;
    }

    # Don't allow direct access to PHP files in the vendor directory.
    location ~ /vendor/.*\.php$ {
        deny all;
        return 404;
    }

    # Protect files and directories from prying eyes.
    location ~* \.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig|\.save)?$|^(\.(?!well-known).*|Entries.*|Repository|Root|Tag|Template|composer\.(json|lock)|web\.config)$|^#.*#$|\.php(~|\.sw[op]|\.bak|\.orig|\.save)$ {
        deny all;
        return 404;
    }

    location ~ '\.php$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
        try_files $fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param QUERY_STRING $query_string;
        fastcgi_intercept_errors on;
        fastcgi_pass php:9000;
        fastcgi_read_timeout 300;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        try_files $uri @rewrite;
        expires max;
        log_not_found off;
        access_log off;
    }

    # Fighting with Styles? This little gem is amazing.
    location ~ ^/sites/.*/files/styles/ {
        try_files $uri @rewrite;
    }

    # Handle private files through Drupal. Private file's path can come
    # with a language prefix.
    location ~ ^(/[a-z\-]+)?/system/files/ {
        try_files $uri /index.php?$query_string;
    }

    # Enforce clean URLs
    # Removes index.php from urls like www.example.com/index.php/my-page
    if ($request_uri ~* "^(.*/)index\.php/(.*)") {
        return 307 $1$2;
    }
}
```
### 4. Cron Configuration (config/cron/drupal-cron)

Create `config/cron/drupal-cron`:
```
# Run Drupal cron every hour
0 * * * * cd /opt/drupal && /usr/local/bin/php -d memory_limit=512M web/core/scripts/drupal.php cron
```
### 5. Environment File (.env)

Create `.env` file for easy configuration:
```
# Project name
COMPOSE_PROJECT_NAME=drupal11

# Drupal version
DRUPAL_VERSION=11.2.8

# Database settings
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal

# PHP settings
PHP_VERSION=8.3
PHP_MEMORY_LIMIT=512M

# Timezone
TZ=Asia/Kolkata

# CUSTOM PORT SETTINGS. ONLY REQUIRED IF THERE IS PORT CONFLICT.
# UNCOMMENT REQUIRED SETTINGS ONLY WITH AVAILABLE PORT

# Traefik Ports
# HTTP_PORT=8000
# HTTPS_PORT=8443
# TRAEFIK_DASHBOARD_PORT=9090

# Database Ports
# MARIADB_PORT=3307

# phpMyAdmin Port
# PHPMYADMIN_DIRECT_PORT=8081

# Mailhog Ports
# MAILHOG_SMTP_PORT=1026
# MAILHOG_WEB_PORT=8026
```
### 6. Hosts File

#### For Linux/macOS

```bash
sudo nano /etc/hosts

# Add the following lines:

127.0.0.1 drupal.localhost
127.0.0.1 pma.localhost
127.0.0.1 mail.localhost
```

#### For Windows

1. Open **Notepad** as Administrator:
    - Click the **Start** button.
    - Type **Notepad** in the search bar.
    - Right-click on **Notepad** and select **Run as administrator**.
    - Confirm any User Account Control prompts.
2. In Notepad, open the hosts file:
    - Go to **File > Open**.
    - Navigate to `C:\Windows\System32\drivers\etc`.
    - If you do not see any files, change the file type filter from "Text Documents (*.txt)" to **All Files (*.*)**.
    - Select the file named **hosts** and open it.
3. Add these lines at the end of the file:
```
127.0.0.1 drupal.localhost
127.0.0.1 pma.localhost
127.0.0.1 mail.localhost
```

4. Save the file and close Notepad.
5. Flush the DNS cache to apply changes:
    - Open the **Command Prompt** (search for "cmd" and run normally).
    - Run the command:

```
ipconfig /flushdns
```


This will ensure your system resolves these hostnames locally to 127.0.0.1 for your Docker containers.
## Directory Structure

Create the following directory structure:
```
project-root/
├── docker-compose.yml
├── .env
├── .gitignore
├── config/
│   ├── nginx/
│   │   └── default.conf
│   ├── php/
│   │   ├── php.ini
│   │   └── php-fpm.conf
│   └── cron/
│       └── drupal-cron
├── drupal/
├── mariadb-init/
│   └── .gitkeep
├── logs/
│   └── nginx/
│       └── .gitkeep
└── traefik/
    └── certs/
        └── .gitkeep
```
## .gitignore

Create `.gitignore`:
```
# Drupal files
drupal/web/sites/*/files
drupal/web/sites/*/private
drupal/vendor/
drupal/web/core/
drupal/web/modules/contrib/
drupal/web/themes/contrib/
drupal/web/profiles/contrib/

# Docker volumes
mariadb-init/*.sql

# Logs
logs/

# Environment
.env.local

# macOS
.DS_Store

# IDE
.idea/
.vscode/
*.swp
*.swo
```

## Setup Instructions

### Step 1: Create Directory Structure
```
mkdir -p drupal11-dev
cd drupal11-dev
mkdir -p config/{nginx,php,cron}
mkdir -p drupal mariadb-init logs/nginx traefik/certs
```
### Step 2: Create Configuration Files

Create all the configuration files mentioned above in their respective directories.

### Step 3: Start Docker Containers
```
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```
### Step 4: Install Drupal

```
# Access the Drupal container
docker-compose exec drupal sh
or
docker-compose exec drupal bash

# Install git in the Drupal container
docker exec -it drupal_php sh
apk update
apk add git
Confirm: git --version.


# Install Drupal with Composer
composer create-project drupal/recommended-project:^11.2.8 /tmp/drupal
mv /tmp/drupal/* /opt/drupal/
mv /tmp/drupal/.* /opt/drupal/ 2>/dev/null || true
rm -rf /tmp/drupal

# Set permissions
chown -R www-data:www-data /opt/drupal/web/sites/default/files
chmod 755 /opt/drupal/web/sites/default
```

### Step 5: Install Drush (Drupal Shell)
```
docker-compose exec drupal sh
cd /opt/drupal
composer require drush/drush

# Test Drush
vendor/bin/drush status
```

### Step 6: Complete Drupal Installation from Web Interface

1. Navigate to `http://drupal.localhost`
2. Follow the installation wizard
3. Use these database credentials:
   - **Database name**: drupal
   - **Database username**: drupal
   - **Database password**: drupal
   - **Host**: mariadb
   - **Port**: 3306
## Screenshots

![](/images/Drupal-Install-1.png "Installation - 1")
![](/images/Drupal-Install-2.png "Installation - 2")
![](/images/Drupal-Install-3.png "Installation - 3")
![](/images/Drupal-Install-4.png "Installation - 4")


## Verify Installation

This section ensures all components are working correctly before proceeding with Drupal configuration.

### 1. Verify Docker Containers

Check that all containers are running and healthy:
```
docker-compose ps
```
**Expected output:**
NAME                 COMMAND                  SERVICE        STATUS      PORTS
drupal_traefik      "traefik --api.insec…"   traefik        Up 2 min    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8080->8080/tcp
drupal_mariadb      "docker-entrypoint.s…"   mariadb        Up 2 min    3306/tcp
drupal_php          "docker-php-entrypoi…"   php            Up 2 min    9000/tcp
drupal_nginx        "nginx -g daemon off;…"  nginx          Up 2 min    80/tcp
drupal_app          "tail -f /dev/null"      drupal         Up 2 min
drupal_phpmyadmin   "/docker-entrypoint.…"  phpmyadmin     Up 1 min    80/tcp
drupal_mailhog      "MailHog"                mailhog        Up 1 min    0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
drupal_cron         "crond -f -l 2"          cron           Up 1 min

All containers should show **Up** status.

### 2. Verify Database Connection

Test that the database is accessible and configured correctly:
```
# Connect to MySQL and check database
docker-compose exec mariadb mysql -u drupal -pdrupal -h mariadb -e "SHOW DATABASES; SELECT DATABASE(); SELECT USER();"
```
**Expected output:**
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

### 3. Verify Drupal Files Structure

Confirm that Drupal is properly installed in the container:
```
# Check Drupal directory structure
docker-compose exec drupal ls -la /opt/drupal/

# Verify key directories exist
docker-compose exec drupal test -d /opt/drupal/web && echo "✓ web directory exists"
docker-compose exec drupal test -d /opt/drupal/vendor && echo "✓ vendor directory exists"
docker-compose exec drupal test -f /opt/drupal/composer.json && echo "✓ composer.json exists"
```
**Expected output:**
✓ web directory exists
✓ vendor directory exists
✓ composer.json exists

### 4. Verify Composer.json Validity

Ensure the composer.json file is valid JSON and contains Drupal configuration:
```
# Check composer.json validity
docker-compose exec drupal cat /opt/drupal/composer.json | head -30

# Verify it's valid JSON
docker-compose exec drupal php -r "json_decode(file_get_contents('/opt/drupal/composer.json')); echo 'JSON is valid';"
```
**Expected output - JSON is valid**

### 5. Verify PHP-FPM Connection

Test that Nginx can communicate with PHP-FPM:
```
# Check PHP version
docker-compose exec php php -v

# Check PHP extensions
docker-compose exec php php -m | grep -E "(pdo|mysql|gd|curl|json)"
```
**Expected output should include:**
- PDO
- pdo_mysql
- gd
- curl
- json

### 6. Verify Nginx Configuration

Ensure Nginx is properly configured to serve Drupal:
```
# Test Nginx configuration
docker-compose exec nginx nginx -t

# Check access to Drupal
curl -I http://localhost/index.php
```
**Expected output:**
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

### 7. Verify Traefik Routing

Check that Traefik is properly routing to all services:
```
# Access Traefik API to view routers
curl http://localhost:8080/api/http/routers

# Check if drupal.localhost route exists
curl http://localhost:8080/api/http/routers | grep -i drupal
```
Should see routing configuration for drupal, phpmyadmin, and mailhog services.

### 8. Verify File Permissions

Ensure Drupal files have correct ownership and permissions:
```
# Check file ownership
docker-compose exec drupal ls -l /opt/drupal/web/sites/default/files

# Verify www-data ownership
docker-compose exec drupal stat -c '%U:%G' /opt/drupal/web/sites/default
```
**Expected output:**
www-data:www-data

### 9. Verify Services Accessibility

Test that all services are accessible via their routes:

**Test via curl:**
```
# Drupal
curl -I http://drupal.localhost/
# Expected: 200 or 302 response

# phpMyAdmin
curl -I http://pma.localhost/
# Expected: 200 response

# Mailhog
curl -I http://mail.localhost/
# Expected: 200 response

# Traefik Dashboard
curl -I http://localhost:8080/dashboard/
# Expected: 200 response
```
### 10. Verify Complete Health Check Script

Run this comprehensive verification script:
```
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

### Troubleshooting Verification Issues

**Issue: Container not starting**
```
# Check container logs
docker-compose logs drupal
docker-compose logs php
docker-compose logs mariadb
```

**Issue: Database connection fails**
```
# Verify MariaDB is running
docker-compose exec mariadb mysql -u root -proot -e "SELECT VERSION();"
```
# Check network connectivity
```
docker-compose exec php ping mariadb
```

**Issue: HTTP 502 Bad Gateway on browser**
```
# Check Nginx and PHP-FPM connectivity
docker-compose logs nginx
docker-compose logs php
```
# Restart PHP-FPM
```
docker-compose restart php
```

**Issue: Traefik not routing properly**
```
# Check Traefik configuration
docker-compose config | grep -A 10 traefik

# Check Traefik logs
docker-compose logs traefik

# Verify service labels
docker-compose ps
```
## Access URLs

After setup, access your services at:

- **Drupal Site**: http://drupal.localhost
- **phpMyAdmin**: http://pma.localhost
- **Mailhog (Email Testing)**: http://mail.localhost or http://localhost:8025
- **Traefik Dashboard**: http://localhost:8080

## Useful Commands

### Container Management
```
# Start services
docker-compose up -d

# Stop services
docker-compose stop

# Restart services
docker-compose restart

# View logs
docker-compose logs -f [service_name]

# Execute commands in containers
docker-compose exec drupal bash
docker-compose exec php sh
docker-compose exec mariadb mysql -u root -p
```

### Drupal/Drush Commands
```
# Access Drupal container
docker-compose exec drupal bash

# Clear cache
vendor/bin/drush cr

# Run cron
vendor/bin/drush cron

# Update database
vendor/bin/drush updb

# Export configuration
vendor/bin/drush cex

# Import configuration
vendor/bin/drush cim

# Install module
vendor/bin/drush en module_name -y

# Backup database
vendor/bin/drush sql:dump > backup.sql
```
### Database Management
```
# Backup database
docker-compose exec mariadb mysqldump -u drupal -pdrupal drupal > backup.sql

# Restore database
docker-compose exec -T mariadb mysql -u drupal -pdrupal drupal < backup.sql

# Access MySQL CLI
docker-compose exec mariadb mysql -u drupal -pdrupal drupal
```
### Performance Tuning
```
# View container resource usage
docker stats

# Restart PHP-FPM (after PHP config changes)
docker-compose restart php

# Restart Nginx (after nginx config changes)
docker-compose restart nginx

# Clear OPcache
docker-compose exec php kill -USR2 1
```
## Mailhog Configuration

Configure Drupal to use Mailhog for email testing:

1. Install SMTP module: `composer require drupal/smtp`
2. Enable module: `drush en smtp -y`
3. Configure at `/admin/config/system/smtp`:
   - **SMTP server**: mailhog
   - **SMTP port**: 1025
   - **Use SSL**: No

Or add to `settings.php`:

$config['smtp.settings']['smtp_host'] = 'mailhog';
$config['smtp.settings']['smtp_port'] = '1025';

## Troubleshooting

### Issue: Permission denied errors
```
# Fix file permissions
docker-compose exec drupal bash
chown -R www-data:www-data /opt/drupal/web/sites/default/files
chmod 755 /opt/drupal/web/sites/default
```
### Issue: Drupal installation fails
```
# Check database connection
docker-compose exec drupal bash
php -r "new PDO('mysql:host=mariadb;dbname=drupal', 'drupal', 'drupal');"
```
### Issue: Nginx 502 Bad Gateway
```
# Check PHP-FPM status
docker-compose logs php

# Restart PHP-FPM
docker-compose restart php
```
### Issue: Traefik routing not working
```
# Check Traefik dashboard
# Visit http://localhost:8080

# Verify labels
docker-compose config

# Restart Traefik
docker-compose restart traefik
```
### Issue: Slow performance on macOS/Windows

Consider using Docker volumes instead of bind mounts, or use docker-sync:
```
# Install docker-sync
gem install docker-sync

# Create docker-sync.yml
# (configuration for optimized file syncing)
```
## Production Considerations

**This setup is for LOCAL DEVELOPMENT ONLY.** For production:

1. ✅ Remove Traefik insecure API access
2. ✅ Use proper SSL certificates
3. ✅ Secure database with strong passwords
4. ✅ Remove phpMyAdmin and Mailhog
5. ✅ Configure proper PHP production settings (disable display_errors)
6. ✅ Set up proper backup strategies
7. ✅ Use Docker secrets for sensitive data
8. ✅ Implement proper logging and monitoring
9. ✅ Configure firewall rules
10. ✅ Use production-grade reverse proxy

## Additional Resources

- [Drupal 11 Documentation](https://www.drupal.org/docs/11)
- [Docker Documentation](https://docs.docker.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Drush Documentation](https://www.drush.org/)

## Support and Maintenance

### Regular Updates
```
# Update Docker images
docker-compose pull

# Update Drupal core
docker-compose exec drupal composer update drupal/core-recommended --with-dependencies

# Update contributed modules
docker-compose exec drupal composer update
```
### Monitoring
```
# Monitor container health
docker-compose ps

# Check resource usage
docker stats

# View all logs
docker-compose logs -f
```
### Post-Installation Verification Checklist

After completing the setup, verify everything is working using this checklist:

- [ ] All 8 containers running (`docker-compose ps`)
- [ ] Database accessible and drupal database exists
- [ ] Drupal files structure correct (/opt/drupal/web, vendor, etc.)
- [ ] composer.json is valid JSON
- [ ] PHP-FPM communicating with Nginx (no 502 errors)
- [ ] Traefik routing all services correctly
- [ ] File permissions set to www-data:www-data
- [ ] All services accessible via localhost URLs
- [ ] Drupal installation wizard displays at http://drupal.localhost
- [ ] phpMyAdmin accessible at http://pma.localhost
- [ ] Mailhog accessible at http://mail.localhost
- [ ] Traefik dashboard accessible at http://localhost:8080

### Quick Verification Command

Run this one command to verify everything:
```
docker-compose exec drupal bash /dev/stdin << 'EOF'
echo "✓ PHP working" && \
php -r "new PDO('mysql:host=mariadb;dbname=drupal', 'drupal', 'drupal'); echo '✓ DB OK' . PHP_EOL;" && \
test -f /opt/drupal/web/index.php && echo "✓ Drupal found" && \
php -m | grep -q pdo_mysql && echo "✓ Extensions OK" && \
echo "✓ All systems ready!"
EOF
```
### Performance Notes

For optimal performance:

- MariaDB allocated 512MB buffer pool (suitable for development)
- PHP memory limit set to 512MB
- Nginx configured with appropriate timeouts
- DNS: Docker's internal DNS resolution used (no external lookups needed)
- Timezone set to Asia/Kolkata (IST)

Adjust these values if you experience slowness:
```
# Check container resource usage
docker stats

# If memory/CPU constrained, reduce PHP children in php-fpm.conf
pm.max_children = 25  # Reduced from 50
pm.start_servers = 3   # Reduced from 5

# Restart containers
docker-compose restart php
```
## Summary

This complete Drupal 11.2.8 Docker environment provides:

1. ✅ **Local Development**: Full Drupal development environment on Docker Desktop
2. ✅ **All Dependencies**: MariaDB, PHP 8.3, Nginx, Traefik, phpMyAdmin, Mailhog, Cron
3. ✅ **Professional Setup**: Production-like configuration with proper networking
4. ✅ **Easy Management**: Docker Compose for one-command setup
5. ✅ **Comprehensive Tools**: Drush, Composer, CLI access to all services
6. ✅ **Email Testing**: Mailhog integrated for email testing
7. ✅ **Database Management**: phpMyAdmin for database administration
8. ✅ **Verification Scripts**: Complete health checks and troubleshooting guides
9. ✅ **Best Practices**: Security, performance, and development optimizations
10. ✅ **India-Optimized**: Timezone and resource settings for local development

You're now ready to develop Drupal 11 applications locally with a professional Docker setup!