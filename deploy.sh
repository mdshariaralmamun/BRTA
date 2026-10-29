#!/usr/bin/env bash
set -e

MSG="${1:-update: publish latest changes}"

# Build the production bundle first so broken code never gets pushed
npm run build
git add -A
git commit -m "$MSG"
git push origin main

echo ""
echo "Pushed to GitHub. If your VPS webhook is set up, the site at"
echo "https://brtc.shariar.dev will update automatically within seconds."
