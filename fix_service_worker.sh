#!/bin/bash
# Fix service worker caching issue

echo "Updating index.html to force service worker refresh..."

# Add timestamp to service worker registration to bust cache
sudo sed -i 's/serviceWorkerVersion: null/serviceWorkerVersion: "'$(date +%s)'"/' /var/www/catastrophe-companion/index.html

# Also update flutter_service_worker.js version
sudo sed -i 's/const CACHE_NAME = .*/const CACHE_NAME = "flutter-app-cache-'$(date +%s)'";/' /var/www/catastrophe-companion/flutter_service_worker.js 2>/dev/null || echo "Service worker file might not exist or pattern not found"

echo "Done! The service worker cache should now be busted."
echo ""
echo "Users will need to:"
echo "1. Close all tabs with the site"
echo "2. Clear browser cache/data for the site"
echo "3. Revisit the site"