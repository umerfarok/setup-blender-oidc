# setup-blender-oidc

This repository contains the Docker Compose stack and configuration required to deploy Apache Guacamole with Google Web SSO (OpenID Connect). This acts as a centralized gateway to map users securely into isolated Linux XRDP environments for Blender.

## Prerequisites for VPS
- Ubuntu 22.04 LTS (Recommended)
- Docker & Docker Compose installed
- Nginx and Certbot (for free SSL)
- A domain name pointing to your VPS IP address.

## VPS Deployment Guide

### 1. Initial Setup
Log into your VPS via SSH and install Docker if you haven't already:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```
*(Logout and log back in for the docker group to take effect).*

### 2. Clone the Repository
Clone this repository to your VPS:
```bash
git clone https://github.com/umerfarok/setup-blender-oidc.git ~/guacamole
cd ~/guacamole
```

### 3. Configure the Environment
Configure your database passwords and Google API Keys:
```bash
cp .env.example .env
nano .env
```
*Make sure to change `GOOGLE_REDIRECT_URI` in the `.env` file to your actual LIVE domain (e.g., `https://workspace.yourdomain.com/guacamole/`)*

### 4. Admin and User Setup
If you need to define your Admin email or pre-create client emails before booting:
```bash
nano data/02-create-test-user.sql
```
*Change `umerfarooq.dev@gmail.com` to your actual admin email.*

### 5. Start the Environment
Boot the system up to ingest the configurations.
```bash
sudo docker-compose up -d
```

### 6. Reverse Proxy & SSL (Nginx)
To provide secure HTTPS access, setup Nginx:
```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y

# Request an SSL certificate for your domain
sudo certbot --nginx -d workspace.yourdomain.com
```

Once Nginx is ready, copy the provided configuration:
```bash
sudo cp nginx-guacamole.conf /etc/nginx/sites-available/guacamole
sudo ln -s /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 7. Final Configuration
1. Go to `https://workspace.yourdomain.com/guacamole/`
2. Sign in with the Google Account you defined as an admin in Step 4.
3. Click your username in the top right -> **Settings** -> **Connections**.
4. Create XRDP connections pointing to `127.0.0.1` and assign them to your generated OpenID users.
