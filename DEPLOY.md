# BRTA — Docker deployment on VPS

Runs as a Docker container alongside your other apps.

## 1. On the VPS — clone and build (one time)

```bash
mkdir -p /opt/apps
cd /opt/apps
git clone https://github.com/YOUR_USERNAME/BRTA.git brta
cd brta
docker compose up -d --build
```

Your app will be live on port **8081**.

## 2. Reverse proxy with Nginx (host)

If you already run Nginx on the VPS for your other app, add a site for BRTA:

```bash
cat > /etc/nginx/sites-available/brta <<'EOF'
server {
    listen 80;
    server_name brtc.shariar.dev;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/brta /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

Add HTTPS:

```bash
certbot --nginx -d brtc.shariar.dev
```

## 3. Auto-update on every GitHub push

Create `/opt/deploy-brta.sh`:

```bash
cat > /opt/deploy-brta.sh <<'EOF'
#!/bin/bash
set -e
cd /opt/apps/brta
git pull origin main
docker compose up -d --build
EOF
chmod +x /opt/deploy-brta.sh
```

Then set up a webhook listener (see step 5-6 in the old guide) or run the script manually after each push:

```bash
/opt/deploy-brta.sh
```
