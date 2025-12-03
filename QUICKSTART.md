# Quick Start Guide

**Get up and running in 3 steps:**

## Step 1: Prerequisites
Ensure you have on Windows:
- ✅ WSL2 with Ubuntu installed
- ✅ Docker Desktop running with WSL2 backend
- ✅ Hosts file updated

## Step 2: Run the installer
```bash
cd drupal-docker
./scripts/install.sh
```

## Step 3: Complete Drupal setup
Open: http://drupal.localhost:8060

---

## Access your services

| Service | URL |
|---------|-----|
| Drupal | http://drupal.localhost:8060 |
| phpMyAdmin | http://pma.localhost:8060 |
| Mailhog | http://mail.localhost:8060 |
| Traefik Dashboard | http://localhost:8080 |

---

For full setup instructions, see README.md
