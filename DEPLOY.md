# brtc.shariar.dev — auto-deploy webhook

Update the site on every push to main.

## One-time setup on the VPS (run once, by you)

```bash
ssh root@YOUR_VPS_IP
```

### 1. Install Node and Nginx

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs nginx git
```

### 2. Clone the repo and build

```bash
mkdir -p /var/www/brtc.shariar.dev
cd /var/www/brtc.shariar.dev
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .
npm install
npm run build
```

### 3. Nginx config

```bash
cat > /etc/nginx/sites-available/brtc.shariar.dev <<'EOF'
server {
    listen 80;
    server_name brtc.shariar.dev;

    root /var/www/brtc.shariar.dev/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/brtc.shariar.dev /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### 4. SSL (HTTPS)

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d brtc.shariar.dev
```

### 5. Webhook to auto-update on every GitHub push

```bash
npm install -g webhook
```

Create `/opt/deploy-brtc.json`:

```json
[
  {
    "id": "brtc-deploy",
    "execute-command": "/opt/deploy-brtc.sh",
    "command-working-directory": "/var/www/brtc.shariar.dev",
    "trigger-rule": {
      "match": { "type": "value", "value": "REPLACE_WITH_SECRET", "parameter": { "source": "header", "name": "X-Webhook-Secret" } }
    }
  }
]
```

Create `/opt/deploy-brtc.sh`:

```bash
cat > /opt/deploy-brtc.sh <<'EOF'
#!/bin/bash
set -e
cd /var/www/brtc.shariar.dev
git pull origin main
npm install
npm run build
EOF
chmod +x /opt/deploy-brtc.sh
```

Run the webhook listener as a service:

```bash
cat > /etc/systemd/system/webhook-brtc.service <<'EOF'
[Unit]
Description=GitHub webhook for brtc.shariar.dev
After=network.target

[Service]
ExecStart=/usr/bin/webhook -hooks /opt/deploy-brtc.json -port 9000 -verbose
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now webhook-brtc
```

### 6. Add the webhook on GitHub

1. Go to your repo on GitHub → Settings → Webhooks → Add webhook.
2. **Payload URL:** `http://YOUR_VPS_IP:9000/hooks/brtc-deploy`
3. **Content type:** `application/json`
4. **Secret:** put a long random string. Use the SAME string in `/opt/deploy-brtc.json` (replace `REPLACE_WITH_SECRET`), then restart the service with `systemctl restart webhook-brtc`.
5. **Trigger:** Just the `push` event.

## After setup — how to update the site

From the Bolt editor or your laptop:

```bash
git add -A
git commit -m "update: describe what changed"
git push origin main
```

GitHub fires the webhook → your VPS runs `git pull && npm install && npm run build` automatically. The site at `https://brtc.shariar.dev` updates within seconds.
