# 🚀 Drupal 11.2.8 WSL2 + Docker Setup Guide

**Version:** 1.0  
**Date:** December 4, 2025  
**Platform:** Windows (WSL2 + Ubuntu + Docker)  
**Drupal Version:** 11.2.8

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [System Prerequisites](#system-prerequisites)
3. [Installation Overview](#installation-overview)
4. [First-Time Setup](#first-time-setup)
5. [Daily Development Workflow](#daily-development-workflow)
6. [Service Architecture](#service-architecture)
7. [Troubleshooting Guide](#troubleshooting-guide)
8. [Quick Reference](#quick-reference)

---

## 📦 Overview

This is a complete, production-ready Drupal development environment designed for Windows developers using WSL2 (Windows Subsystem for Linux 2) and Docker containers.

### What's Included

The package provides a fully containerized Drupal 11.2.8 development stack with:
- Latest stable Drupal 11.2.8
- PHP 8.3 with FPM (FastCGI Process Manager)
- MariaDB 10.11 database server
- Nginx web server for handling HTTP requests
- Traefik reverse proxy for managing local domains
- phpMyAdmin for graphical database management
- Mailhog for testing and capturing emails
- Composer for PHP dependency management
- Drush command-line tool for Drupal administration
- Automated cron service running every 15 minutes

### Key Benefits

- **Single Command Setup:** Complete installation with one script execution
- **Repeatable Across Machines:** Consistent environment regardless of your Windows system
- **System Isolation:** Development environment completely isolated from your system PHP and databases
- **Database Inspection:** Easy access to database management through phpMyAdmin
- **Email Testing:** Test email functionality without sending real emails
- **Local Domains:** Pretty local domain names (drupal.localhost) instead of port numbers
- **Configurable Ports:** All service ports can be customized through environment variables

---

## ⚙️ System Prerequisites

### Windows Machine Requirements

Your Windows machine must meet these minimum specifications:
- Windows 10 (Build 19041 or later) or Windows 11
- Minimum 8GB RAM (16GB recommended for better performance)
- At least 20GB free disk space for Drupal files and databases
- Administrator access to install required software
- Virtualization enabled in BIOS (usually enabled by default)

### Required Software to Install

Three main components need to be installed on your Windows machine:

#### 1. WSL2 and Ubuntu

WSL2 allows you to run a Linux environment natively on Windows. Ubuntu is the Linux distribution we'll use. This needs to be enabled and installed through PowerShell.

**What you're setting up:** A Linux terminal environment on your Windows machine where all development work will happen.

#### 2. Docker Desktop

Docker Desktop is the containerization platform that runs all services (Drupal, database, web server, etc.) in isolated containers.

**What you're setting up:** The Docker engine that will run and manage all the development containers. Configuration includes enabling WSL2 integration so Docker can work with your Ubuntu environment.

**Important settings to configure:**
- Enable "Use WSL 2 based engine" in General settings
- Enable WSL Integration specifically for Ubuntu in Resources settings
- Allow Docker to restart when settings are applied

#### 3. Composer in Ubuntu

Composer is a PHP dependency manager that will download and install Drupal and all its dependencies. It must be installed within your Ubuntu environment.

**What you're setting up:** PHP command-line environment in Ubuntu with essential extensions (XML, GD, cURL, mbstring, ZIP, intl) and Composer.

---

## 📥 Installation Overview

The installation process is designed to be straightforward and happens in specific steps:

### Step 1: Prepare the Repository

Clone the pre-configured Drupal template repository from GitHub into your projects directory in Ubuntu. This repository contains the Docker configuration, initialization scripts, and setup files needed for your environment.

**Location:** Your project will be stored in the Ubuntu home directory under a projects folder.

### Step 2: Configure Local Domain Names

Update your Windows hosts file to map local domain names to your localhost. This allows you to access services using pretty names like `drupal.localhost` instead of `localhost:8061`.

**Why:** The Traefik reverse proxy routes traffic based on domain names, making development more convenient and realistic.

**Domain mappings needed:**
- `drupal.localhost` → Drupal website
- `pma.localhost` → phpMyAdmin interface
- `mail.localhost` → Mailhog email testing interface

### Step 3: Prepare Scripts

Make the helper scripts executable within Ubuntu. These scripts automate common tasks like installation, running Drush commands, and resetting the environment.

**Scripts included:**
- `install.sh` - Main setup and installation script
- `drush.sh` - Wrapper for running Drush commands
- `reset.sh` - Complete reset and cleanup

### Step 4: Configure Environment

Create an environment configuration file (.env) from the provided template. This file allows you to customize ports, database credentials, and other settings. The default values work for most developers; customization is optional.

**Configurable elements:**
- HTTP port (default: 8060)
- Individual service ports (nginx, phpMyAdmin, mailhog)
- Database credentials
- Project naming

### Step 5: Run Installation Script

Execute the main installation script which automates the following:
- Starts all Docker containers
- Waits for services to be ready
- Downloads and installs Drupal 11.2.8 using Composer
- Sets up file permissions
- Displays access information

**Estimated time:** 2-3 minutes for complete installation.

---

## 🚀 First-Time Setup

After running the installation script, the next phase is the Drupal installation wizard in your browser.

### Accessing the Drupal Installer

Navigate to the Drupal URL provided by the installation script. The browser will present the Drupal installation wizard.

### Installation Wizard Steps

**Language Selection:**
Choose your preferred language for the Drupal interface (English recommended).

**Installation Profile:**
Select the "Standard" profile, which includes common modules and configurations suitable for most projects.

**Database Configuration:**
The wizard will ask for database connection details. Important: Use the internal container name `db` as the host (not localhost), as containers communicate through Docker's internal network:

- Database type: MySQL or MariaDB (both work with MariaDB 10.11)
- Host: `db` (the container name)
- Port: `3306` (default MariaDB port)
- Database name: `drupal`
- Username: `drupal`
- Password: `drupal`

**Site Configuration:**
Configure basic site settings:
- Site name: Enter your project name
- Admin email: Your email address for receiving notifications
- Admin username: Create an administrative account username
- Admin password: Create a strong password for administration

**Completion:**
After all settings are configured and saved, Drupal installation completes automatically. You'll be redirected to the administrative dashboard.

---

## 📍 Service Architecture

The environment consists of multiple coordinated services working together:

### Drupal Web Server

**Purpose:** Serves your Drupal website and handles all HTTP requests

**Access:** Through Traefik at `drupal.localhost` (or direct via `localhost:8061`)

**Powered by:** Nginx web server and PHP-FPM

**What happens here:** Browser requests for your website come here, PHP processes the request with Drupal, and responses are sent back.

### Database Server (MariaDB)

**Purpose:** Stores all Drupal content, configuration, and user data

**Access:** Through phpMyAdmin or direct connection from Drupal container

**Direct access:** Not typically needed during development; use phpMyAdmin instead

**Configuration:**
- Database: `drupal`
- Default user credentials: `drupal` / `drupal`
- Performance tuning enabled for development workloads

### Database Management (phpMyAdmin)

**Purpose:** Provides graphical interface for database administration, viewing, and testing

**Access:** `pma.localhost` (or direct via `localhost:8081`)

**When to use:** Inspecting database structure, running SQL queries, backing up data, troubleshooting database issues

### Email Testing (Mailhog)

**Purpose:** Captures and displays emails sent from Drupal for testing

**Access:** `mail.localhost` (or direct via `localhost:8025`)

**When to use:** Testing email functionality without sending actual emails; viewing email content, subject lines, and attachments

**SMTP Configuration:** Drupal mail settings use `mailhog` as host and `1025` as SMTP port

### Reverse Proxy (Traefik)

**Purpose:** Routes traffic to correct containers based on domain names; manages local domain routing

**Access:** Dashboard at `localhost:8080`

**Why it's useful:** Eliminates need to remember port numbers; provides centralized service monitoring

### Drush Administration Tool

**Purpose:** Provides command-line interface for Drupal administration tasks

**Used for:** Cache clearing, database updates, module management, status checking, custom commands

**How it works:** Runs inside a dedicated container with access to Drupal files and database

### Automated Cron Service

**Purpose:** Executes Drupal's scheduled tasks automatically

**Frequency:** Runs every 15 minutes

**What it does:** Handles maintenance tasks, scheduled jobs, and background processing

---

## 💻 Daily Development Workflow

### Starting Development

Each development session begins with starting the Docker containers. This brings all services online and makes your Drupal site accessible.

**What to expect:**
- Containers start in order based on dependencies
- Services take a few seconds to become ready
- All local domains become accessible
- Drupal is available at its local URL

### Stopping Development

When you're done working, stop the containers to free system resources. Stopping containers doesn't delete your data; everything persists in Docker volumes.

**What happens:**
- All containers shut down gracefully
- Services become inaccessible
- Data remains safely stored in volumes
- Restarting resumes exactly where you left off

### Common Development Tasks

**Clearing Drupal Cache:** Drupal maintains caches to improve performance. During development, you'll frequently need to clear caches when making changes to themes or configurations. A wrapper script simplifies this process.

**Checking Drupal Status:** View Drupal's current status, including database connection, installed modules, and recent errors. Useful for diagnostics and troubleshooting.

**Running Database Updates:** When updating Drupal core or modules, database schema updates may be required. This command applies pending updates safely.

**Managing Modules:** Enable or disable modules through the command line. Faster than the web interface for bulk operations.

**Listing Installed Modules:** View all installed modules with their current status (enabled/disabled) and version information.

### Database Access and Management

phpMyAdmin provides a complete graphical interface for database work:

**Database Viewing:** Browse all tables, examine data structure, see existing content

**SQL Queries:** Run custom SQL queries for complex operations, data manipulation, or testing

**Data Export:** Backup database or export data in various formats

**Data Import:** Restore from backups or import external data

**Credentials:** Use the same `drupal` / `drupal` credentials from the database configuration

### Email Testing Workflow

During development, configure Drupal to send emails through Mailhog:

**Configuration:** Set mail system to use `mailhog` as the SMTP host and port `1025`

**Sending:** Any email generated by Drupal gets intercepted and stored

**Viewing:** All intercepted emails appear in the Mailhog web interface with full content, headers, and attachments

**Testing:** Verify email content without actual emails being sent to real addresses

---

## 🔧 Troubleshooting Guide

### Local Domain Names Not Loading

**Symptoms:** Browser shows "Host not found" or connection timeout when accessing `drupal.localhost`

**Possible Causes:**
- Containers not running
- Host file not properly configured
- DNS caching issue
- Firewall blocking

**Solution Steps:**
1. Verify containers are running through Docker commands
2. Start containers if they're stopped
3. Check container logs for error messages
4. Verify host file entries exist in Windows

### Host Name Resolution Failures

**Symptoms:** Cannot reach services by domain name; direct IP/port works

**Possible Cause:** Windows hosts file not updated correctly or incorrectly encoded

**Solution:**
- Open the hosts file as administrator from a text editor
- Verify the exact line with all three domain names exists
- Check file is saved as plain text (UTF-8 encoding)
- Flush DNS cache from Windows to clear stale entries

### Port Already in Use

**Symptoms:** Installation fails with "port already in use" error

**Possible Cause:** Another application is using one of the configured ports

**Solution:**
1. Identify which port is conflicting
2. Edit the .env file to change port numbers to unused ports
3. Stop existing containers
4. Start containers again with new configuration
5. Update host file if ports changed

### Composer Installation Errors

**Symptoms:** PHP extension-related errors during installation

**Possible Cause:** Required PHP extensions not installed in Ubuntu

**Solution:** Install missing PHP extensions in Ubuntu. The required extensions are: XML, GD, cURL, mbstring, ZIP, and international.

### Database Connection Failures

**Symptoms:** Drupal installer fails at database step; connection error

**Possible Causes:**
- Wrong credentials entered
- Incorrect host name (should be container name `db`, not localhost)
- Database service not running
- Network communication failure

**Solution:** 
- Verify exact credentials match initial configuration
- Ensure host is `db` not `localhost` or IP address
- Check database container is running and healthy
- Review database container logs for errors

### Docker Permission Errors

**Symptoms:** "Permission denied" errors when running docker commands

**Possible Cause:** Current user not in docker group

**Solution:** Add user to docker group and activate group membership. Log out and back in for changes to take effect.

### Setting Up Clean Environment

**When needed:** If installation goes wrong and you want to start fresh

**Available tool:** Reset script that removes all containers, volumes, and data

**Important:** This permanently deletes all data; only use if you're certain you want to start over

**Alternative:** Manual cleanup of Docker components for more control

### Resetting All Docker Data

**Warning:** This removes everything related to this project

**What gets removed:** All containers, all volumes (database data), all networks

**Use case:** Complete reset needed; previous installation corrupted

**After reset:** Run installation script again to rebuild from scratch

---

## 📂 Project Structure Overview

Once installed, the project directory contains:

**Drupal Installation Directory:** Contains the complete Drupal codebase downloaded by Composer, including core, modules, themes, and vendor libraries.

**Configuration Directory:** Stores Nginx configuration for the web server and other service configurations.

**Scripts Directory:** Contains helper bash scripts for installation, Drush operations, and cleanup.

**Configuration Files:**
- Docker Compose configuration defining all services and their settings
- Environment configuration file with customizable parameters
- Git ignore rules for version control
- Docker ignore rules for image building

**Documentation:** Complete README with detailed instructions

---

## 🔄 Environment Configuration

The .env file allows customization without modifying core configurations:

### Configuration Elements

**Project Identification:** Name used in container naming and identification

**HTTP Traffic Port:** Main port for browser access through Traefik; this is the port you use for `drupal.localhost:PORT`

**Individual Service Ports:** Direct ports for each service bypassing Traefik (useful for debugging)

**Database Credentials:** Username, password, and database name

**Database Port:** Port for direct database access

### Port Details

**HTTP Port:** Used by Traefik for all domain-based traffic (main access port)

**Service-Specific Ports:** Direct container ports for access without Traefik routing

**Mailhog SMTP:** Port for mail clients to connect to Mailhog for testing

**Traefik Dashboard:** Port for accessing Traefik's monitoring interface

### Variable Syntax

Configuration uses a fallback system: if a value is not set, a default is used. This means you only need to set values you want to change from defaults.

---

## ✅ Installation Checklist

Before starting, ensure all prerequisites are met:

- [ ] Windows 10 (Build 19041+) or Windows 11 installed
- [ ] Virtualization enabled in BIOS
- [ ] Administrator access available
- [ ] At least 8GB RAM available
- [ ] At least 20GB free disk space
- [ ] WSL2 enabled and Ubuntu installed
- [ ] Docker Desktop installed and running
- [ ] WSL2 integration enabled in Docker settings
- [ ] Composer installed in Ubuntu with PHP extensions
- [ ] All three domain names added to Windows hosts file

### Post-Installation Verification

After running the installation script:

- [ ] All containers show as running
- [ ] Local domains resolve (ping drupal.localhost from Ubuntu)
- [ ] Drupal installer loads in browser
- [ ] Database connection succeeds with provided credentials
- [ ] Drupal installation completes without errors
- [ ] You can log in with created admin account
- [ ] phpMyAdmin loads and shows database
- [ ] Mailhog loads and shows test interface
- [ ] Traefik dashboard displays all services

---

## 🎯 Quick Reference

### Essential Access Points

| Service | Local Domain | Purpose |
|---------|--------------|---------|
| Drupal Website | drupal.localhost | Your Drupal site |
| Database Manager | pma.localhost | Database administration |
| Email Testing | mail.localhost | Captured emails |
| Service Monitor | localhost:8080 | System dashboard |

### First-Time Sequence

1. Install WSL2 and Ubuntu
2. Install Docker Desktop
3. Install Composer in Ubuntu
4. Update Windows hosts file
5. Clone project repository
6. Run installation script
7. Complete Drupal installer in browser
8. Start developing

### Regular Workflow

1. Start containers at session beginning
2. Access Drupal through browser
3. Make changes to Drupal, themes, modules
4. Clear cache when needed
5. Test emails through Mailhog
6. Stop containers at session end

### Useful Information

**All services use Docker internal networking:** Use container names as hostnames (e.g., `db` for database)

**Data persistence:** Database and files persist in Docker volumes; survive container restarts

**Port conflicts:** Change ports in .env if needed; no code modifications required

**Database access:** Three ways - through Drupal, phpMyAdmin, or direct container connection

---

## 📞 Support Resources

**Drupal Documentation:** Official Drupal platform documentation and guides

**Docker Compose Documentation:** Complete Docker Compose reference and examples

**Traefik Documentation:** Reverse proxy configuration and advanced routing

**WSL Documentation:** Windows Subsystem for Linux features and troubleshooting

---

## 🎉 Final Notes

This setup provides a complete, professional development environment for Drupal. All services are configured to work together seamlessly, and most common development tasks are simplified through wrapper scripts and pre-configured settings.

The environment is designed to be repeatable: you can delete everything and recreate it identically on any Windows machine, making it perfect for team development, backup scenarios, or trying different configurations.

**Document Version:** 1.0  
**Last Updated:** December 4, 2025

---

## ❓ Questions or Clarifications?

Is there any part of this guide that needs clarification or additional detail? Please let me know:

- Areas that are unclear
- Steps you'd like more explanation on
- Specific workflow scenarios you need guidance for
- Troubleshooting issues you anticipate
- Additional information you'd like included
