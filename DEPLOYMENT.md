# Deployment Guide for Catastrophe Companion

## Quick Deploy

To deploy the Flutter web app to your EC2 instance:

```bash
python deploy.py
```

## What the Deploy Script Does

1. **Builds** the Flutter web app locally in release mode
2. **Creates a backup** of the current deployment on the server
3. **Uploads** the new build to the EC2 instance
4. **Sets permissions** for nginx to serve the files
5. **Restarts nginx** to ensure changes take effect
6. **Cleans up** old backups (keeps last 3)

## Prerequisites

- Flutter installed and in PATH
- Python 3 installed
- SSH key file at: `C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem`
- EC2 instance accessible at: `3.20.223.76`

## First Time Setup

If nginx is not configured yet on your EC2 instance:

1. SSH into your instance:
   ```bash
   ssh -i "C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem" ubuntu@3.20.223.76
   ```

2. Copy the nginx configuration:
   ```bash
   sudo cp /path/to/nginx.conf.example /etc/nginx/sites-available/catastrophe-companion
   sudo ln -s /etc/nginx/sites-available/catastrophe-companion /etc/nginx/sites-enabled/
   sudo nginx -t  # Test configuration
   sudo systemctl restart nginx
   ```

## Manual Deployment (if script fails)

1. Build locally:
   ```bash
   flutter build web --release
   ```

2. Upload to server:
   ```bash
   scp -i "C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem" -r build/web/* ubuntu@3.20.223.76:/var/www/catastrophe-companion/
   ```

3. Fix permissions on server:
   ```bash
   ssh -i "C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem" ubuntu@3.20.223.76
   sudo chown -R www-data:www-data /var/www/catastrophe-companion
   sudo chmod -R 755 /var/www/catastrophe-companion
   sudo systemctl restart nginx
   ```

## Troubleshooting

- **Build fails**: Ensure Flutter is properly installed and `flutter doctor` shows no issues
- **Upload fails**: Check SSH key permissions and EC2 security group allows SSH (port 22)
- **Site not accessible**: Ensure EC2 security group allows HTTP (port 80)
- **404 errors**: Check nginx error logs: `sudo tail -f /var/log/nginx/error.log`

## Access Your App

After successful deployment, access your app at:
- http://3.20.223.76

Consider setting up a domain name and SSL certificate for production use.