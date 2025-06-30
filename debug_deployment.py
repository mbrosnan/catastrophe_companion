#!/usr/bin/env python3
"""
Debug script to help troubleshoot deployment issues
"""

import os
import subprocess
import sys

# Configuration
EC2_HOST = "3.20.223.76"
EC2_USER = "ubuntu"
SSH_KEY = r"C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem"
REMOTE_DIR = "/var/www/catastrophe-companion"

def run_test(command, description):
    """Run a test command and report results"""
    print(f"\n📋 Testing: {description}")
    print(f"   Command: {command}")
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"   ✅ Success")
            if result.stdout:
                print(f"   Output: {result.stdout.strip()}")
        else:
            print(f"   ❌ Failed (exit code: {result.returncode})")
            if result.stderr:
                print(f"   Error: {result.stderr.strip()}")
        return result.returncode == 0
    except Exception as e:
        print(f"   ❌ Exception: {e}")
        return False

print("🔍 Catastrophe Companion Deployment Debugger")
print("=" * 50)

# Test 1: Check local environment
print("\n1️⃣ LOCAL ENVIRONMENT CHECKS")

# Check Flutter
run_test("flutter --version", "Flutter installation")

# Check if we're in the right directory
if os.path.exists("pubspec.yaml"):
    print("   ✅ pubspec.yaml found - in Flutter project directory")
else:
    print("   ❌ pubspec.yaml not found - not in Flutter project directory")

# Check if build exists
if os.path.exists("build/web"):
    print("   ✅ build/web directory exists")
    file_count = len([f for r, d, files in os.walk("build/web") for f in files])
    print(f"   📁 Contains {file_count} files")
else:
    print("   ❌ build/web directory not found - need to run 'flutter build web'")

# Check SSH key
if os.path.exists(SSH_KEY):
    print(f"   ✅ SSH key found at {SSH_KEY}")
else:
    print(f"   ❌ SSH key not found at {SSH_KEY}")

# Test 2: SSH Connection
print("\n2️⃣ SSH CONNECTION TEST")
ssh_test = f'ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "echo Connection successful"'
run_test(ssh_test, "SSH connection to EC2")

# Test 3: Remote server checks
print("\n3️⃣ REMOTE SERVER CHECKS")

# Check if directory exists
dir_test = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "if [ -d {REMOTE_DIR} ]; then echo exists; else echo missing; fi"'
run_test(dir_test, f"Check if {REMOTE_DIR} exists")

# Check directory permissions
perm_test = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "ls -la /var/www/ | grep catastrophe"'
run_test(perm_test, "Check directory permissions")

# Check nginx status
nginx_test = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo systemctl is-active nginx"'
run_test(nginx_test, "Nginx service status")

# Check nginx config
nginx_config_test = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "ls -la /etc/nginx/sites-enabled/ | grep catastrophe"'
run_test(nginx_config_test, "Nginx configuration for catastrophe-companion")

# Check if port 80 is listening
port_test = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo netstat -tlnp | grep :80"'
run_test(port_test, "Port 80 listening status")

# Test 4: Try to access the site
print("\n4️⃣ WEB ACCESS TEST")
import urllib.request
import urllib.error

try:
    response = urllib.request.urlopen(f"http://{EC2_HOST}", timeout=5)
    print(f"   ✅ Site is accessible at http://{EC2_HOST}")
    print(f"   📄 Response code: {response.getcode()}")
except urllib.error.HTTPError as e:
    print(f"   ❌ HTTP Error: {e.code} - {e.reason}")
except urllib.error.URLError as e:
    print(f"   ❌ URL Error: {e.reason}")
except Exception as e:
    print(f"   ❌ Error accessing site: {e}")

# Test 5: Check nginx error logs
print("\n5️⃣ NGINX ERROR LOGS (last 10 lines)")
log_test = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo tail -10 /var/log/nginx/error.log"'
run_test(log_test, "Nginx error logs")

print("\n" + "=" * 50)
print("🏁 Debug complete. Check the results above to identify issues.")
print("\nCommon issues:")
print("- If SSH fails: Check EC2 security group allows SSH (port 22)")
print("- If web access fails: Check EC2 security group allows HTTP (port 80)")
print("- If nginx config missing: Need to set up nginx configuration")
print("- If directory missing: The deploy script should create it")