# VM Deployment Guide

This guide documents the recommended rebuild path for a normal Ubuntu GPU VM.

It is written for the architecture that actually worked:

- host OS: Ubuntu 22.04
- desktop: XFCE4 + XRDP
- Blender: installed directly on the host
- Guacamole: Docker Compose from this repo
- reverse proxy: Nginx
- auth: Google OpenID / Google Workspace

## 1. Recommended VM Shape

- Ubuntu 22.04 LTS
- NVIDIA GPU attached
- public ports `22`, `80`, `443`
- enough disk for Blender, projects, and PostgreSQL
- a stable public IP

If possible, use a provider that gives you direct VM networking rather than a
containerized pod abstraction.

## 2. DNS

Before enabling Google login and TLS, point your subdomain to the VM:

- `workspace.yourdomain.com -> <vm-public-ip>`

Wait for DNS to resolve correctly before requesting TLS certificates.

## 3. Base Packages

Install the base system packages:

```bash
sudo apt update
sudo apt install -y \
  xfce4 xfce4-goodies xrdp xorgxrdp dbus-x11 x11-xserver-utils \
  nginx certbot python3-certbot-nginx \
  curl wget git unzip ca-certificates gnupg lsb-release
```

Set XFCE as the default desktop for new XRDP users:

```bash
echo startxfce4 | sudo tee /etc/skel/.xsession
```

## 4. Create Linux Users

Create one Linux user per team member:

```bash
sudo adduser andrew
sudo adduser al
sudo adduser dags
sudo adduser kristofers
sudo adduser ammillers
```

If you are using one shared default password during setup:

```bash
echo 'andrew:BlenderWorkspace2026!' | sudo chpasswd
echo 'al:BlenderWorkspace2026!' | sudo chpasswd
echo 'dags:BlenderWorkspace2026!' | sudo chpasswd
echo 'kristofers:BlenderWorkspace2026!' | sudo chpasswd
echo 'ammillers:BlenderWorkspace2026!' | sudo chpasswd
```

## 5. Shared Project Storage

If your VM has a larger secondary disk, mount it and use it for projects.

Example shared project directory:

```bash
sudo mkdir -p /workspace/Blender_Projects
sudo chmod 777 /workspace/Blender_Projects
```

Add a desktop shortcut for each user:

```bash
for user in andrew al dags kristofers ammillers; do
  sudo -u "$user" mkdir -p "/home/$user/Desktop"
  sudo ln -sfn /workspace/Blender_Projects "/home/$user/Desktop/Persistent_Projects"
  sudo chown -h "$user:$user" "/home/$user/Desktop/Persistent_Projects"
done
```

## 6. Install NVIDIA Drivers

Use the driver path recommended by your provider image when possible.

If the VM does not already have a working NVIDIA stack:

```bash
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot
```

Verify after reboot:

```bash
nvidia-smi
```

## 7. Install Blender On The Host

Do not rely on the Ubuntu package if you need a specific Blender version.

Example for Blender `4.5.2`:

```bash
sudo mkdir -p /workspace/software
cd /workspace/software
wget https://download.blender.org/release/Blender4.5/blender-4.5.2-linux-x64.tar.xz
tar -xf blender-4.5.2-linux-x64.tar.xz
sudo ln -sfn /workspace/software/blender-4.5.2-linux-x64 /workspace/software/blender
sudo ln -sfn /workspace/software/blender/blender /usr/local/bin/blender
blender --version
```

Optional desktop launcher:

```bash
sudo cp /workspace/software/blender/blender.desktop /usr/share/applications/blender.desktop
sudo sed -i 's|^Exec=.*|Exec=/workspace/software/blender/blender %f|' /usr/share/applications/blender.desktop
sudo sed -i 's|^Icon=.*|Icon=/workspace/software/blender/blender.svg|' /usr/share/applications/blender.desktop
```

## 8. Verify GPU Rendering In Blender

Inside Blender:

1. `Edit -> Preferences -> System`
2. Select `CUDA` or `OptiX`
3. Enable the NVIDIA GPU
4. In `Render Properties`, set:
   - `Render Engine = Cycles`
   - `Device = GPU Compute`

Then run a test render and confirm from the VM:

```bash
nvidia-smi
```

## 9. Install Docker

On a normal VM, Docker Compose is the preferred way to run Guacamole:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker "$USER"
newgrp docker
docker --version
docker compose version
```

## 10. Clone This Repository

```bash
cd /opt
sudo git clone https://github.com/umerfarok/setup-blender-oidc.git guacamole
sudo chown -R "$USER:$USER" /opt/guacamole
cd /opt/guacamole
```

## 11. Configure The Repo

Copy the env file:

```bash
cp .env.example .env
```

Edit `.env` and set:

```env
POSTGRES_PASSWORD=change-me
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_REDIRECT_URI=https://workspace.yourdomain.com/guacamole/
```

Review the seeded user file if needed:

- [`data/02-create-test-user.sql`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\data\02-create-test-user.sql)

Review the Nginx host:

- [`nginx-guacamole.conf`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\nginx-guacamole.conf)

## 12. Start Guacamole

Bootstrap the DB files:

```bash
chmod +x init.sh
./init.sh
```

Start the stack:

```bash
docker compose up -d
docker compose ps
docker compose logs -f postgres guacd guacamole
```

## 13. Configure Nginx

Copy the Nginx config:

```bash
sudo cp nginx-guacamole.conf /etc/nginx/sites-available/guacamole
sudo ln -s /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/guacamole
sudo nginx -t
sudo systemctl reload nginx
```

## 14. Issue TLS Certificates

After DNS points to the VM:

```bash
sudo certbot --nginx -d workspace.yourdomain.com
```

## 15. Configure Google OAuth

In Google Cloud:

- application type: `Web application`
- authorized JavaScript origin:
  - `https://workspace.yourdomain.com`
- authorized redirect URI:
  - `https://workspace.yourdomain.com/guacamole/`

If using Google Workspace only, configure the app scope/access policy on the
Google side accordingly.

## 16. Assign Connections In Guacamole

After first login as the admin user:

1. open `https://workspace.yourdomain.com/guacamole/`
2. sign in with the admin Google account
3. go to `Settings -> Connections`
4. create one RDP connection per Linux user

Each connection should point to:

- hostname: `127.0.0.1`
- port: `3389`
- username: matching Linux user
- password: that Linux user password

Example names:

- `Andrew Desktop`
- `Al Desktop`
- `Dags Desktop`
- `Kristofers Desktop`
- `Ammillers Desktop`

Assign each connection to the matching Guacamole/OpenID user.

## 17. Validation Checklist

Validate all of the following:

- `https://workspace.yourdomain.com/guacamole/` opens
- Google sign-in works
- each user sees only their assigned connection
- XRDP session opens successfully
- Blender launches inside the session
- Blender can access `/workspace/Blender_Projects`
- `nvidia-smi` shows Blender during render tests

## 18. Operational Notes

- On a real VM, this stack is simpler and more stable than the RunPod pod
  version.
- Keep Blender and XRDP on the host.
- Keep Guacamole, PostgreSQL, and guacd in Docker Compose.
- Do not point production DNS at unstable pod IPs.
- If you later migrate from a temporary URL to a final domain, update:
  - Google OAuth redirect URI
  - `.env`
  - Nginx `server_name`

## 19. Backup Suggestions

At minimum, back up:

- `/workspace/Blender_Projects`
- repo `.env`
- PostgreSQL volume / Guacamole database
- user assignment documentation

## 20. If You Must Rebuild

On a new VM, the fastest rebuild order is:

1. base OS packages
2. NVIDIA driver verification
3. XFCE + XRDP
4. Linux users
5. Blender host install
6. clone this repo
7. `.env` configuration
8. `docker compose up -d`
9. Nginx + Certbot
10. Google OAuth redirect check
11. Guacamole connection assignment
12. per-user login tests
