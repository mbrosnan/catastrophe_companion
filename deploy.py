#!/usr/bin/env python3
"""
Deploy script for Catastrophe Companion Flutter web app to EC2
"""

import os
import sys
import subprocess
import shutil
from datetime import datetime

# Configuration
EC2_HOST = "3.20.223.76"
EC2_USER = "ubuntu"
SSH_KEY = r"C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem"
REMOTE_DIR = "/var/www/catastrophe-companion"
BUILD_DIR = "build/web"

# Colors for output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_step(message):
    """Print a colored step message"""
    print(f"\n{Colors.OKBLUE}==> {message}{Colors.ENDC}")

def print_success(message):
    """Print a colored success message"""
    print(f"{Colors.OKGREEN}✓ {message}{Colors.ENDC}")

def print_error(message):
    """Print a colored error message"""
    print(f"{Colors.FAIL}✗ {message}{Colors.ENDC}")

def run_command(command, description, capture_output=False):
    """Run a command and handle errors"""
    print_step(description)
    try:
        if capture_output:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
            return result.stdout
        else:
            subprocess.run(command, shell=True, check=True)
        print_success(f"{description} completed")
        return True
    except subprocess.CalledProcessError as e:
        print_error(f"{description} failed: {e}")
        if capture_output and e.stderr:
            print(e.stderr)
        return False

def main():
    """Main deployment process"""
    print(f"{Colors.HEADER}{Colors.BOLD}Catastrophe Companion Deployment Script{Colors.ENDC}")
    print(f"Deploying to: {EC2_USER}@{EC2_HOST}:{REMOTE_DIR}")
    
    # Step 1: Clean previous build
    print_step("Cleaning previous build")
    if os.path.exists(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
        print_success("Previous build cleaned")
    
    # Step 2: Build Flutter web app
    if not run_command("flutter build web --release", "Building Flutter web app"):
        print_error("Build failed. Exiting.")
        sys.exit(1)
    
    # Step 3: Check if build directory exists
    if not os.path.exists(BUILD_DIR):
        print_error(f"Build directory {BUILD_DIR} not found. Build may have failed.")
        sys.exit(1)
    
    # Step 4: Create backup on server
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "if [ -d {REMOTE_DIR} ]; then sudo cp -r {REMOTE_DIR} {REMOTE_DIR}_backup_{timestamp}; fi"'
    run_command(backup_cmd, "Creating backup on server")
    
    # Step 5: Create remote directory if it doesn't exist
    create_dir_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo mkdir -p {REMOTE_DIR}"'
    if not run_command(create_dir_cmd, "Creating remote directory"):
        print_error("Failed to create remote directory. Exiting.")
        sys.exit(1)
    
    # Step 6: Set proper permissions for upload
    perm_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo chown -R {EC2_USER}:{EC2_USER} {REMOTE_DIR}"'
    run_command(perm_cmd, "Setting upload permissions")
    
    # Step 7: Upload files using SCP
    scp_cmd = f'scp -i "{SSH_KEY}" -r {BUILD_DIR}/* {EC2_USER}@{EC2_HOST}:{REMOTE_DIR}/'
    if not run_command(scp_cmd, "Uploading files to server"):
        print_error("Upload failed. Exiting.")
        sys.exit(1)
    
    # Step 8: Set proper ownership and permissions for nginx
    fix_perm_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo chown -R www-data:www-data {REMOTE_DIR} && sudo chmod -R 755 {REMOTE_DIR}"'
    run_command(fix_perm_cmd, "Setting nginx permissions")
    
    # Step 9: Reload systemd and restart nginx
    reload_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo systemctl daemon-reload"'
    run_command(reload_cmd, "Reloading systemd daemon")
    
    restart_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo systemctl restart nginx"'
    if not run_command(restart_cmd, "Restarting nginx"):
        print_warning("Failed to restart nginx. You may need to restart it manually.")
    
    # Step 10: Verify nginx is running
    status_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "sudo systemctl is-active nginx"'
    status = run_command(status_cmd, "Checking nginx status", capture_output=True)
    
    if status and "active" in status:
        print_success("Nginx is running")
    else:
        print_error("Nginx may not be running properly")
    
    # Clean up old backups (keep only last 3)
    cleanup_cmd = f'ssh -i "{SSH_KEY}" {EC2_USER}@{EC2_HOST} "ls -t {REMOTE_DIR}_backup_* 2>/dev/null | tail -n +4 | xargs -r sudo rm -rf"'
    run_command(cleanup_cmd, "Cleaning up old backups")
    
    print(f"\n{Colors.OKGREEN}{Colors.BOLD}Deployment completed successfully!{Colors.ENDC}")
    print(f"Your app should be available at: http://{EC2_HOST}")
    print(f"\nBackup created at: {REMOTE_DIR}_backup_{timestamp}")

def print_warning(message):
    """Print a colored warning message"""
    print(f"{Colors.WARNING}⚠ {message}{Colors.ENDC}")

if __name__ == "__main__":
    # Check if Flutter is available
    try:
        # Try running flutter with shell=True for Windows
        result = subprocess.run("flutter --version", shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            raise subprocess.CalledProcessError(result.returncode, "flutter")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print_error("Flutter not found. Please ensure Flutter is installed and in your PATH.")
        print_warning("Try running 'flutter --version' in this terminal to verify Flutter is accessible.")
        sys.exit(1)
    
    # Check if SSH key exists
    if not os.path.exists(SSH_KEY):
        print_error(f"SSH key not found at: {SSH_KEY}")
        sys.exit(1)
    
    # Check if we're in a Flutter project
    if not os.path.exists("pubspec.yaml"):
        print_error("pubspec.yaml not found. Please run this script from the Flutter project root.")
        sys.exit(1)
    
    # Run deployment
    try:
        main()
    except KeyboardInterrupt:
        print_error("\nDeployment cancelled by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)