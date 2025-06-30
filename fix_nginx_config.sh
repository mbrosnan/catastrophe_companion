#!/bin/bash
# Script to fix nginx configuration

# Check current nginx config
echo "Current nginx configuration (/etc/nginx/sites-available/cc):"
echo "=================================================="
sudo cat /etc/nginx/sites-available/cc
echo ""
echo "=================================================="

# Create new config for catastrophe-companion
echo "Creating new nginx config..."
sudo tee /etc/nginx/sites-available/catastrophe-companion << 'EOF'
server {
    listen 80;
    listen [::]:80;
    
    # Serve both IP and domain
    server_name 3.20.223.76 catastrophecompanion.com www.catastrophecompanion.com;
    
    root /var/www/catastrophe-companion;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    gzip_vary on;
    
    # Disable access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

# Disable old config and enable new one
echo "Updating nginx configuration..."
sudo rm /etc/nginx/sites-enabled/cc
sudo ln -s /etc/nginx/sites-available/catastrophe-companion /etc/nginx/sites-enabled/

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

# Reload nginx
echo "Reloading nginx..."
sudo systemctl reload nginx

echo "Done! Configuration updated."
echo ""
echo "NOTE: You still need to update your DNS:"
echo "1. Go to your DNS provider (looks like Cloudflare based on the IP)"
echo "2. Update the A record for catastrophecompanion.com to point to: 3.20.223.76"
echo "3. If using Cloudflare, you might want to disable proxy (orange cloud) initially for testing"