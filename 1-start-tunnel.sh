#!/bin/bash
# STEP 1: Start Cloudflare Tunnel

echo "========================================================="
echo "PIGRECO - Cloudflare Tunnel"
echo "========================================================="
echo ""
echo "Starting tunnel... Watch for a URL like:"
echo "  https://abc-xyz-123.trycloudflare.com"
echo ""
echo "Copy that URL, then open a NEW terminal and run:"
echo "  ./2-deploy.sh"
echo ""
echo "Keep this window OPEN to maintain the tunnel!"
echo "========================================================="
echo ""

# Check if cloudflared is installed
if command -v cloudflared &> /dev/null; then
    cloudflared tunnel --url http://localhost:3000
elif [ -f "./cloudflared" ]; then
    ./cloudflared tunnel --url http://localhost:3000
else
    echo "ERROR: cloudflared not found!"
    echo ""
    echo "Please install cloudflared:"
    echo "  macOS:   brew install cloudflared"
    echo "  Linux:   sudo apt install cloudflared"
    echo "  Or download from: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
    exit 1
fi
