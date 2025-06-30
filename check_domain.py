#!/usr/bin/env python3
"""
Check domain configuration and deployment
"""

import subprocess
import socket

EC2_HOST = "3.20.223.76"
EC2_USER = "ubuntu"
SSH_KEY = r"C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem"
DOMAIN = "catastrophecompanion.com"

print("🔍 Domain Configuration Check")
print("=" * 50)

# Check DNS resolution
print(f"\n1️⃣ DNS Resolution for {DOMAIN}")
try:
    ip = socket.gethostbyname(DOMAIN)
    print(f"   Domain resolves to: {ip}")
    if ip == EC2_HOST:
        print(f"   ✅ Domain points to your EC2 instance")
    else:
        print(f"   ❌ Domain points to different IP (not {EC2_HOST})")
except Exception as e:
    print(f"   ❌ DNS lookup failed: {e}")

# Check nginx virtual hosts
print(f"\n2️⃣ Nginx Configuration on Server")
cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo ls -la /etc/nginx/sites-enabled/"'
try:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print("   Enabled sites:")
    print(result.stdout)
except Exception as e:
    print(f"   Error: {e}")

# Check for domain-specific config
print(f"\n3️⃣ Looking for domain-specific nginx config")
cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo grep -r catastrophecompanion /etc/nginx/sites-enabled/"'
try:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.stdout:
        print("   Found domain references:")
        print(result.stdout)
    else:
        print("   No domain-specific configuration found")
except Exception as e:
    print(f"   Error: {e}")

# Check document roots
print(f"\n4️⃣ Checking nginx document roots")
cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo grep -r \'root \' /etc/nginx/sites-enabled/ | grep -v \'#\'"'
try:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print("   Document roots configured:")
    print(result.stdout)
except Exception as e:
    print(f"   Error: {e}")

# List /var/www contents
print(f"\n5️⃣ Contents of /var/www/")
cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "ls -la /var/www/"'
try:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout)
except Exception as e:
    print(f"   Error: {e}")

print("\n" + "=" * 50)
print("📋 Next Steps:")
print("1. If DNS points elsewhere, update your DNS records")
print("2. If nginx serves from different directory, update nginx config")
print("3. Check if there's a separate config file for the domain")
print("4. Clear any CDN/CloudFlare cache if applicable")