
# Steps to Use Non-Default Ports Across Full Tech Stack

## Overview: Default vs Custom Ports

| Service              | Default Port | Custom Port | Purpose                |
|----------------------|--------------|-------------|------------------------|
| **HTTP (Traefik)**   | 80           | 8000        | Web traffic            |
| **HTTPS (Traefik)**  | 443          | 8443        | Secure web traffic     |
| **Traefik Dashboard**| 8080         | 9090        | Traefik admin interface|
| **MariaDB**          | 3306         | 3307        | Database server        |
| **phpMyAdmin**       | 80           | 8081        | Database management UI |
| **Mailhog SMTP**     | 1025         | 1026        | Email SMTP server      |
| **Mailhog Web UI**   | 8025         | 8026        | Email web interface    |
| **Nginx**            | 80 (internal)| *no change* | Internal only          |
| **PHP-FPM**          | 9000 (internal)| *no change* | Internal only         |

---

## 1. Custom Port Configuration File

Add below variables to `.env` in your project root: (ONLY ADD FOR SERVICE WHICH HAS PORT CONFLICT)

```env
# Traefik Ports
HTTP_PORT=8000
HTTPS_PORT=8443
TRAEFIK_DASHBOARD_PORT=9090

# Database Ports
MARIADB_PORT=3307

# phpMyAdmin Port
PHPMYADMIN_DIRECT_PORT=8081

# Mailhog Ports
MAILHOG_SMTP_PORT=1026
MAILHOG_WEB_PORT=8026
```

---

## 2. docker-compose.yml Example (with Custom Ports)

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    ports:
      - "${HTTP_PORT:-8000}:80"
      - "${HTTPS_PORT:-8443}:443"
      - "${TRAEFIK_DASHBOARD_PORT:-9090}:8080"
    networks:
      - drupal_network

  mariadb:
    image: mariadb:10.11
    ports:
      - "${MARIADB_PORT:-3307}:3306"
    networks:
      - drupal_network

  phpmyadmin:
    image: phpmyadmin:5.2
    ports:
      - "${PHPMYADMIN_DIRECT_PORT:-8081}:80"
    networks:
      - drupal_network

  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "${MAILHOG_SMTP_PORT:-1026}:1025"
      - "${MAILHOG_WEB_PORT:-8026}:8025"
    networks:
      - drupal_network

networks:
  drupal_network:
    driver: bridge
```

---

## 3. Update .env With Port Vars

```env
COMPOSE_PROJECT_NAME=drupal11
DRUPAL_VERSION=11.2.8
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal

PHP_VERSION=8.3
PHP_MEMORY_LIMIT=512M
TZ=Asia/Kolkata

# Custom Port Vars
HTTP_PORT=8000
HTTPS_PORT=8443
TRAEFIK_DASHBOARD_PORT=9090
MARIADB_PORT=3307
PHPMYADMIN_DIRECT_PORT=8081
MAILHOG_SMTP_PORT=1026
MAILHOG_WEB_PORT=8026
```

---

## 4. Check for Port Conflicts

### For Linux/Mac

```bash
lsof -i :8000
lsof -i :8443
lsof -i :9090
lsof -i :3307
lsof -i :8081
lsof -i :1026
lsof -i :8026
```

Or all at once:

```bash
for port in 8000 8443 9090 3307 8081 1026 8026; do
  lsof -i :$port && echo "Port $port in use";
done
```

### For Windows

```bash
netstat -ano | findstr :8000
netstat -ano | findstr :8443
netstat -ano | findstr :9090
netstat -ano | findstr :3307
netstat -ano | findstr :8081
netstat -ano | findstr :1026
netstat -ano | findstr :8026
```


---

## 5. Start Services with Custom Ports

```bash
docker-compose up -d
docker-compose ps
```

---

## 6. Custom URLs to Access Services

| Service              | URL                                | Notes                          |
|----------------------|------------------------------------|-------------------------------|
| **Drupal Site**      | http://localhost:8000              | Via custom HTTP port           |
| **Drupal (HTTPS)**   | https://localhost:8443             | Custom HTTPS port              |
| **phpMyAdmin**       | http://pma.localhost:8000          | Traefik routing                |
| **phpMyAdmin (Direct)** | http://localhost:8081           | Direct access                  |
| **Mailhog Web UI**   | http://localhost:8026              | Email testing interface        |
| **Traefik Dashboard**| http://localhost:9090              | Admin interface                |
| **MariaDB**          | localhost:3307                     | For external DB tooling        |

---

## 7. Drupal Database Connection

When installing Drupal, use:

- Database name: `drupal`
- Username: `drupal`
- Password: `drupal`
- Host: `mariadb` *(internal)* or `localhost` *(external)*
- Port: `3306` *(internal)* or `3307` *(external)*

---

## 8. Mailhog SMTP Example

```php
$config['smtp.settings']['smtp_host'] = 'mailhog';
$config['smtp.settings']['smtp_port'] = '1025'; // Use internal container port
```

---

## 9. Hosts File (Optional)

```bash
sudo nano /etc/hosts

# Add:
127.0.0.1 drupal.localhost
127.0.0.1 pma.localhost
127.0.0.1 mail.localhost
```

---

## 10. Verification with Custom Ports

```bash
curl -I http://localhost:8000
curl -I http://localhost:9090
curl -I http://localhost:8081
curl -I http://localhost:8026

docker-compose exec mariadb mysql -u drupal -pdrupal -h localhost -P 3306 -e "SELECT 1"
mysql -h 127.0.0.1 -P 3307 -u drupal -pdrupal -e "SELECT 1"
```

---

## Quick Reference Script

```bash
#!/bin/bash
source .env
PORTS=( "$HTTP_PORT:HTTP" "$HTTPS_PORT:HTTPS" "$TRAEFIK_DASHBOARD_PORT:Traefik Dashboard" "$MARIADB_PORT:MariaDB" "$PHPMYADMIN_DIRECT_PORT:phpMyAdmin" "$MAILHOG_SMTP_PORT:Mailhog SMTP" "$MAILHOG_WEB_PORT:Mailhog Web" )
ALL_CLEAR=true
for port_info in "${PORTS[@]}"; do
  IFS=':' read -r port name <<< "$port_info"
  if lsof -i :$port > /dev/null 2>&1; then
    echo "⚠️  Port $port ($name) is IN USE"
    ALL_CLEAR=false
  else
    echo "✓ Port $port ($name) is available"
  fi

done
if [ "$ALL_CLEAR" = true ]; then
  echo "✓ All ports are available. Safe to run: docker-compose up -d"
else
  echo "⚠️  Some ports are in use. Please update .env"
fi
```

---

## Best Practices

- Document all custom ports in your repo (`PORTS.md`)
- Use environment variables, avoid hardcoding
- Check ports before starting containers
- Update documentation and share with your team

---

Your entire Drupal stack is now accessible via custom ports—making it easy to avoid conflicts and run multiple stacks side-by-side.
