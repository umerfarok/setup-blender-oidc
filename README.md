# setup-blender-oidc

This repository contains the Apache Guacamole configuration used to front a
multi-user Blender workstation with Google OpenID login.

The intended production shape is:

- Ubuntu 22.04 GPU VM
- XFCE + XRDP on the host
- Blender installed on the host
- Guacamole + PostgreSQL + guacd from this repo
- Nginx in front of Guacamole
- Google Workspace / Google login via OpenID

## Important Note About RunPod

This repo can be used on a normal Ubuntu VM with Docker Compose.

It is not a good fit for nested Docker inside a restricted RunPod pod. On
RunPod we had to pivot to a native host install because Docker-in-Docker and
normal `80/443` ingress were not reliable there.

If you are rebuilding on a normal VM instead of RunPod, follow the VM guide:

[VM Deployment Guide](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\VM-DEPLOYMENT.md)

## Quick Start For A Normal VM

1. Provision an Ubuntu 22.04 GPU VM with public `80/443` access.
2. Install NVIDIA drivers, XFCE, XRDP, Docker, Nginx, and Certbot.
3. Install Blender on the host.
4. Clone this repo and configure [`.env.example`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\.env.example).
5. Start the Guacamole stack with Docker Compose.
6. Put Nginx in front of Guacamole and issue the TLS certificate.
7. Verify Google login, then verify each XRDP desktop connection.

## Repository Files

- [`docker-compose.yml`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\docker-compose.yml): Guacamole, PostgreSQL, and guacd services
- [`data/02-create-test-user.sql`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\data\02-create-test-user.sql): pre-created Guacamole OpenID users
- [`nginx-guacamole.conf`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\nginx-guacamole.conf): Nginx reverse proxy config
- [`init.sh`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\init.sh): Guacamole database bootstrap helper

## Environment Variables

Copy [`.env.example`](C:\Users\Umer Farooq\Desktop\Workspace\alex-blender\.env.example)
to `.env` and set at minimum:

- `POSTGRES_PASSWORD`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_REDIRECT_URI`

For production, the redirect URI must exactly match the final URL used by
users, for example:

```env
GOOGLE_REDIRECT_URI=https://workspace.yourdomain.com/guacamole/
```

## Notes

- Blender itself runs on the host, not inside the Guacamole containers.
- The Linux users and their XRDP sessions are separate from Guacamole users.
- Guacamole users must still be assigned connections after first boot.
- On a real VM, the simplest stable path is host XRDP + host Blender + Docker
  Compose for Guacamole.
