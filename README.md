# 🚀 Drupal WSL2 + Docker Setup - Complete Instructions

**Document Version:** 1.0  
**Date:** December 2, 2025  
**Platform:** Windows (WSL2 + Ubuntu + Docker)  
**Drupal Version:** 11.2.8

---

## 📋 Table of Contents

1. [Package Overview](#package-overview)
2. [What's Inside](#whats-inside)
3. [System Prerequisites](#system-prerequisites)
4. [Installation Steps](#installation-steps)
5. [First-Time Setup](#first-time-setup)
6. [Daily Usage](#daily-usage)
7. [Troubleshooting](#troubleshooting)
8. [Service Details](#service-details)
9. [File Structure](#file-structure)

---

## 📦 Package Overview

This is a **complete, production-ready Drupal development environment** for Windows developers using WSL2 and Docker.

### What You Get:
- ✅ Drupal 11.2.8 (latest stable)
- ✅ PHP 8.3 with FPM
- ✅ MariaDB 10.11
- ✅ Nginx web server
- ✅ Traefik reverse proxy with pretty local domains
- ✅ phpMyAdmin for database management
- ✅ Mailhog for email testing
- ✅ Composer for dependency management
- ✅ All ports configurable via `.env`
- ✅ Ready-to-use helper scripts

### Key Benefits:
- 🎯 One command setup: `./scripts/install.sh`
- 🔄 Repeatable across machines
- 🛡️ Isolated from system PHP/database
- 📊 Easy database inspection with phpMyAdmin
- 📧 Email testing without sending real emails
- 🌐 Pretty local domains (drupal.localhost instead of localhost:8061)

---

## 📁 What's Inside

```
drupal-docker-setup.zip
└── drupal-docker/
    ├── README.md                          # Full documentation
    ├── QUICKSTART.md                      # Quick reference
    ├── PROJECT_CONTENTS.txt               # This package contents
    ├── docker-compose.yml                 # Docker configuration
    ├── .env.example                       # Environment template
    ├── .gitignore                         # Git ignore rules
    ├── config/
    │   └── nginx/
    │       └── default.conf               # Nginx configuration
    └── scripts/
        ├── install.sh                     # Setup script
        ├── drush.sh                       # Drush wrapper
        └── reset.sh                       # Cleanup script
```

**Drupal files** will be generated in `drupal/` directory after first run.

---

## ⚙️ System Prerequisites

### Windows Machine Requirements:
- Windows 10 (Build 19041+) or Windows 11
- At least 8GB RAM (16GB recommended)
- At least 20GB free disk space
- Administrator access

### Required Software (One-time installation):

#### 1. Enable WSL2 & Install Ubuntu
```powershell
# Open PowerShell as Administrator
wsl --install -d Ubuntu

# Restart when prompted
# After reboot, open Ubuntu from Start Menu
```

#### 2. Install Docker Desktop
1. Download from: https://www.docker.com/products/docker-desktop
2. Install with default options
3. Settings → General → Ensure "Use WSL 2 based engine" is checked
4. Settings → Resources → WSL Integration → Turn ON for Ubuntu
5. Click Apply & Restart

#### 3. Install Composer in Ubuntu (Important Step)
```bash
# Inside Ubuntu terminal:
sudo apt update
sudo apt install -y php-cli php-xml php-gd php-curl php-mbstring php-zip php-intl composer

# Verify:
composer --version
```

---

## 📥 Installation Steps

### Do all project work inside "Ubuntu", not PowerShell/Command Prompt.

### Step 1: Clone the GIT Repo
```bash
# In Ubuntu (WSL2):
cd ~
mkdir -p projects
cd projects
git clone <GIT_REPO_URL> drupal-docker
cd drupal-docker
```
### Step 2: Update Hosts File (Windows)
1. Open **Notepad as Administrator**
2. Open file: `C:\Windows\System32\drivers\etc\hosts`
3. Add this line at the bottom:
   ```
   127.0.0.1 drupal.localhost pma.localhost mail.localhost
   ```
4. Save and close

### Step 3: Make Scripts Executable (Back to Ubuntu)
```bash
# In Ubuntu, inside drupal-docker/
chmod +x scripts/*.sh
```

### Step 4: Create .env File
```bash
cp .env.example .env

# (Optional) Edit .env if you want to change default ports based on requirement:
# nano .env
```

### Step 5: Run Installation
```bash
./scripts/install.sh
```

**This will:**
- Start all Docker containers
- Wait for services to be ready
- Download and install Drupal 11.2.8 via Composer
- Display access information

⏱️ **Estimated time:** 2-3 minutes

---

## 🚀 First-Time Setup

After running `./scripts/install.sh`, open your browser:

### Access Drupal Installer
1. Go to: **http://drupal.localhost:8060**
2. Choose language (English)
3. Select "Standard" profile
4. Database settings:
   - **Database type:** MySQL, MariaDB
   - **Host:** `db`
   - **Port:** `3306`
   - **Database name:** `drupal`
   - **Username:** `drupal`
   - **Password:** `drupal`

5. Configure site:
   - **Site name:** Your project name
   - **Admin email:** admin@example.com
   - **Admin username:** admin
   - **Admin password:** Create strong password

6. Installation complete! You're now at `/admin`

---

## 📍 Service Access

| Service | URL | Purpose |
|---------|-----|---------|
| **Drupal** | http://drupal.localhost:8060 | Your Drupal website |
| **phpMyAdmin** | http://pma.localhost:8060 | Database management |
| **Mailhog** | http://mail.localhost:8060 | Email capture & testing |
| **Traefik Dashboard** | http://localhost:8080 | Service monitoring |

### Direct Container Access (Optional)
- **Nginx (direct):** http://localhost:8061
- **phpMyAdmin (direct):** http://localhost:8081
- **Mailhog SMTP:** localhost:1025 (for mail config)

---

## 💻 Daily Usage

### Start Development
```bash
cd ~/projects/drupal-docker

# Start all containers
docker compose up -d

# View logs (optional)
docker compose logs -f
```

### Common Drupal Operations

```bash
# Clear cache
./scripts/drush.sh cr

# Check status
./scripts/drush.sh status

# Run database updates
./scripts/drush.sh updb

# Enable a module
./scripts/drush.sh en modulename

# Disable a module
./scripts/drush.sh dis modulename

# List all modules
./scripts/drush.sh pm:list
```

### Access Database
1. Open: http://pma.localhost:8060
2. Login:
   - **Username:** drupal
   - **Password:** drupal

### Test Emails
1. Configure Drupal email to use:
   - **Host:** mailhog
   - **Port:** 1025 (SMTP)
2. Send any email from Drupal
3. View in Mailhog: http://mail.localhost:8060

### Stop Containers
```bash
docker compose down
```

---

## 🔧 Troubleshooting

### Issue: `drupal.localhost:8060` not loading

**Cause:** Containers not running or network issue

**Solution:**
```bash
# Check running containers
docker ps

# Start if needed
docker compose up -d

# Check logs
docker compose logs
```

---

### Issue: Host name not resolved

**Cause:** Hosts file not updated correctly

**Solution:**
1. Open `C:\Windows\System32\drivers\etc\hosts` as Administrator
2. Verify this line exists:
   ```
   127.0.0.1 drupal.localhost pma.localhost mail.localhost
   ```
3. Save and close (no ANSI encoding, UTF-8)
4. Flush DNS (Windows PowerShell as Administrator):
   ```powershell
   ipconfig /flushdns
   ```

---

### Issue: Port already in use

**Cause:** Another application is using port 8060/8061/etc

**Solution:**
1. Edit `.env`:
   ```env
   HTTP_PORT=8070        # Changed from 8060
   NGINX_PORT=8071       # Changed from 8061
   PHPMYADMIN_PORT=8091  # Changed from 8081
   ```

2. Restart containers:
   ```bash
   docker compose down
   docker compose up -d
   ```

3. Update hosts file:
   ```
   127.0.0.1 drupal.localhost pma.localhost mail.localhost
   ```

---

### Issue: Composer errors about missing extensions

**Cause:** PHP extensions not installed in Ubuntu

**Solution:**
```bash
sudo apt update
sudo apt install -y php-xml php-gd php-curl php-mbstring php-zip php-intl
```

---

### Issue: Database connection fails in installer

**Cause:** Wrong database credentials

**Solution:**
Verify you're using exactly:
- Host: `db` (not localhost or 127.0.0.1)
- Database: `drupal`
- User: `drupal`
- Password: `drupal`
- Port: `3306` (if asked)

---

### Issue: Docker commands give permission errors

**Cause:** User not in docker group

**Solution:**
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

---

## 🐳 Service Details

### MariaDB
- **Image:** mariadb:10.11
- **Port:** 3306 (configurable)
- **Root password:** root
- **Database:** drupal
- **User:** drupal / drupal

### PHP-FPM
- **Image:** drupal:11.2.8-php8.3-fpm-alpine
- **Version:** PHP 8.3
- **Working directory:** /opt/drupal
- **Includes:** All required PHP extensions

### Nginx
- **Image:** nginx:1.25-alpine
- **Port:** 8061 direct (configurable)
- **Config:** config/nginx/default.conf
- **Serves:** /opt/drupal/web

### Traefik
- **Image:** traefik:v2.10
- **Port:** 8060 for HTTP, 8080 for dashboard
- **Purpose:** Routes drupal.localhost → nginx, etc.

### phpMyAdmin
- **Image:** phpmyadmin:5.2
- **Port:** 8081 direct (configurable)
- **URL:** pma.localhost:8060

### Mailhog
- **Image:** mailhog/mailhog
- **SMTP Port:** 1025
- **Web Port:** 8025 direct, 8060 via Traefik
- **Purpose:** Capture and view test emails

---

## 📂 File Structure

```
~/projects/drupal-docker/
├── drupal/                          # Generated Drupal installation
│   ├── web/
│   │   ├── core/
│   │   ├── modules/
│   │   ├── themes/
│   │   └── index.php
│   ├── vendor/                      # Composer packages
│   └── composer.json
│
├── config/
│   └── nginx/
│       └── default.conf             # Nginx configuration
│
├── scripts/
│   ├── install.sh                   # Setup script
│   ├── drush.sh                     # Drush wrapper
│   └── reset.sh                     # Reset script
│
├── docker-compose.yml               # Docker services definition
├── .env                             # Environment variables (auto-created)
├── .env.example                     # Environment template
├── .gitignore                       # Git ignore rules
├── .dockerignore                    # Docker ignore rules
├── README.md                        # Full documentation
└── QUICKSTART.md                    # Quick reference
```

---

## 🔄 Environment Variables (.env)

### Available Variables

```env
# Project name (used in container names)
PROJECT_NAME=drupal

# Traefik HTTP port (main access port)
HTTP_PORT=8060

# Direct container ports
NGINX_PORT=8061
PHPMYADMIN_PORT=8081
MAILHOG_WEB_PORT=8025
MAILHOG_SMTP_PORT=1025
TRAEFIK_DASHBOARD_PORT=8080

# Database
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal
MARIADB_PORT=3306
```

### Variable Format
Variables use `${VAR:-default}` syntax:
- If `HTTP_PORT=8070` → use 8070
- If `HTTP_PORT` not set → use default 8060

---

## 🆘 Getting Help

### Useful Commands

```bash
# View running containers
docker compose ps

# View logs for all services
docker compose logs

# View logs for specific service
docker compose logs php
docker compose logs nginx
docker compose logs db

# Execute command inside container
docker compose exec php bash
docker compose exec db mysql -u drupal -p drupal

# Stop all containers
docker compose down

# Stop and remove all data
docker compose down -v

# Rebuild containers
docker compose up -d --build
```

### Reset Everything
```bash
./scripts/reset.sh
# Follow the prompts to confirm
```

---

## 📚 Additional Resources

- **Drupal Documentation:** https://www.drupal.org/documentation
- **Docker Compose Docs:** https://docs.docker.com/compose
- **Traefik Docs:** https://doc.traefik.io
- **WSL Documentation:** https://docs.microsoft.com/en-us/windows/wsl

---

## ✅ Checklist for First Run

- [ ] WSL2 installed with Ubuntu
- [ ] Docker Desktop installed and running
- [ ] Composer installed in Ubuntu
- [ ] Hosts file updated with `127.0.0.1 drupal.localhost pma.localhost mail.localhost`
- [ ] ZIP extracted to ~/projects/drupal-docker
- [ ] Scripts made executable: `chmod +x scripts/*.sh`
- [ ] .env file created: `cp .env.example .env`
- [ ] Installation run: `./scripts/install.sh`
- [ ] Drupal installer opened: http://drupal.localhost:8060
- [ ] Database credentials entered (db / drupal / drupal / drupal)
- [ ] Admin account created
- [ ] Drupal homepage loads successfully

---

## 🎉 Quick Reference

```bash
# First time
cd ~/projects/drupal-docker
./scripts/install.sh
# Open http://drupal.localhost:8060

# Daily
docker compose up -d          # Start
docker compose down           # Stop
./scripts/drush.sh cr         # Clear cache
./scripts/drush.sh updb       # Database updates

# Emergency reset
./scripts/reset.sh
```

---

**Document created: December 2, 2025**  
**Latest update: Version 1.0**

For the most current version and updates, check the README.md file included in the package.

---

## 📞 Support

If you encounter issues:

1. **Check troubleshooting section** above
2. **Review README.md** for detailed documentation
3. **Check docker logs:** `docker compose logs`
4. **Reset and reinstall:** `./scripts/reset.sh && ./scripts/install.sh`

Happy coding! 🚀