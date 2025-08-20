Run locally on chrome: flutter run -d chrome

ssh -i "C:\Users\mitch\Downloads\catastrophe-companion-ec2-key.pem" ubuntu@3.20.223.76

Two ubuntu commands to run on EC2 to clear some cache to help people reload

sudo sed -i 's/serviceWorkerVersion: null/serviceWorkerVersion: "'$(date +%s)'"/' /var/www/catastrophe-companion/index.html

sudo sed -i 's/const CACHE_NAME = .*/const CACHE_NAME = "flutter-app-cache-'$(date +%s)'";/' /var/www/catastrophe-companion/flutter_service_worker.js


Building for android: 

flutter clean

flutter build appbundle --obfuscate `
    --split-debug-info=build\symbols


deploy to web: python deploy.py