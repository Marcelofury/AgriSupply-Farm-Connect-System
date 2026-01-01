# AgriSupply Deployment Guide

This guide covers deploying the AgriSupply system to production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Backend Deployment](#backend-deployment)
- [Flutter App Deployment](#flutter-app-deployment)
- [Database Setup](#database-setup)
- [Environment Configuration](#environment-configuration)
- [Monitoring & Logging](#monitoring--logging)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before deploying, ensure you have:

- [ ] Supabase project created
- [ ] Payment provider accounts (MTN, Airtel, Flutterwave)
- [ ] OpenAI API key
- [ ] Firebase project (for push notifications)
- [ ] Domain name configured
- [ ] SSL certificates

---

## Backend Deployment

### Option 1: Railway

Railway offers simple, fast deployment with automatic SSL.

1. **Create Railway Account**
   - Sign up at [railway.app](https://railway.app)
   - Connect your GitHub account

2. **Create New Project**
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli
   
   # Login
   railway login
   
   # Initialize project
   cd backend
   railway init
   ```

3. **Configure Environment Variables**
   - Go to Railway Dashboard → Your Project → Variables
   - Add all variables from `.env.example`

4. **Deploy**
   ```bash
   railway up
   ```

5. **Get Public URL**
   - Railway provides a `*.up.railway.app` URL
   - Configure custom domain in Settings

### Option 2: Render

Render offers free tier with managed infrastructure.

1. **Create Render Account**
   - Sign up at [render.com](https://render.com)

2. **Create Web Service**
   - New → Web Service
   - Connect GitHub repository
   - Select `backend` folder as root

3. **Configure Build Settings**
   ```yaml
   Build Command: npm install
   Start Command: npm start
   ```

4. **Add Environment Variables**
   - Go to Environment tab
   - Add all required variables

5. **Deploy**
   - Render auto-deploys on push to main branch

### Option 3: Docker on VPS

For full control, deploy Docker on a VPS (DigitalOcean, Linode, AWS EC2).

1. **Provision Server**
   - Ubuntu 22.04 LTS recommended
   - Minimum 2GB RAM, 1 vCPU

2. **Install Docker**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo apt install docker-compose-plugin
   ```

3. **Clone Repository**
   ```bash
   git clone https://github.com/agrisupply/agrisupply.git
   cd agrisupply
   ```

4. **Configure Environment**
   ```bash
   cp .env.example .env
   nano .env  # Edit with production values
   ```

5. **Deploy with Docker Compose**
   ```bash
   docker compose up -d
   ```

6. **Setup Nginx Reverse Proxy**
   ```bash
   # Install Nginx
   sudo apt install nginx
   
   # Configure SSL with Certbot
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d api.agrisupply.ug
   ```

7. **Nginx Configuration**
   ```nginx
   # /etc/nginx/sites-available/agrisupply
   server {
       listen 443 ssl;
       server_name api.agrisupply.ug;
       
       ssl_certificate /etc/letsencrypt/live/api.agrisupply.ug/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/api.agrisupply.ug/privkey.pem;
       
       location / {
           proxy_pass http://localhost:5000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       }
   }
   ```

---

## Flutter App Deployment

### Android (Google Play Store)

1. **Update Version**
   ```yaml
   # pubspec.yaml
   version: 1.0.0+1  # version_name+version_code
   ```

2. **Generate Keystore**
   ```bash
   keytool -genkey -v -keystore ~/agrisupply-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias agrisupply
   ```

3. **Configure Signing**
   ```properties
   # android/key.properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=agrisupply
   storeFile=/path/to/agrisupply-keystore.jks
   ```

4. **Update build.gradle**
   ```groovy
   // android/app/build.gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }
   
   android {
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile file(keystoreProperties['storeFile'])
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

5. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

6. **Upload to Play Console**
   - Go to [Play Console](https://play.google.com/console)
   - Create new app
   - Upload AAB to Production track
   - Complete store listing

### iOS (App Store)

1. **Configure Xcode**
   ```bash
   cd ios
   pod install
   open Runner.xcworkspace
   ```

2. **Setup Signing**
   - Open Xcode → Runner → Signing & Capabilities
   - Select your Team
   - Configure Bundle Identifier

3. **Build Archive**
   ```bash
   flutter build ipa --release
   ```

4. **Upload to App Store Connect**
   - Open `build/ios/archive/Runner.xcarchive` in Xcode
   - Product → Distribute App
   - Select App Store Connect

5. **Complete App Store Listing**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Add app information, screenshots
   - Submit for review

---

## Database Setup

### Supabase Configuration

1. **Create Project**
   - Go to [supabase.com](https://supabase.com)
   - Create new project
   - Note the project URL and keys

2. **Run Schema Migration**
   ```sql
   -- Open SQL Editor in Supabase Dashboard
   -- Paste contents of database/schema.sql
   -- Click Run
   ```

3. **Configure Authentication**
   - Go to Authentication → Providers
   - Enable Email/Password
   - Configure Google OAuth
   - Setup Phone OTP (Twilio/MessageBird)

4. **Setup Storage Buckets**
   ```sql
   -- Run in SQL Editor
   INSERT INTO storage.buckets (id, name, public) VALUES 
     ('profile-photos', 'profile-photos', true),
     ('product-images', 'product-images', true),
     ('review-images', 'review-images', true),
     ('ai-images', 'ai-images', false),
     ('documents', 'documents', false);
   ```

5. **Configure Row Level Security**
   - Enable RLS on all tables
   - Apply policies from schema.sql

---

## Environment Configuration

### Production Environment Variables

```env
# Server
NODE_ENV=production
PORT=5000

# Supabase (use production project)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# JWT (use strong secret)
JWT_SECRET=your-production-jwt-secret-minimum-32-characters
JWT_EXPIRES_IN=7d

# OpenAI
OPENAI_API_KEY=sk-...

# MTN Mobile Money (Production)
MTN_API_KEY=your-mtn-production-key
MTN_API_SECRET=your-mtn-production-secret
MTN_CALLBACK_URL=https://api.agrisupply.ug/api/v1/payments/mtn/callback
MTN_ENVIRONMENT=production

# Airtel Money (Production)
AIRTEL_CLIENT_ID=your-airtel-production-id
AIRTEL_CLIENT_SECRET=your-airtel-production-secret
AIRTEL_CALLBACK_URL=https://api.agrisupply.ug/api/v1/payments/airtel/callback
AIRTEL_ENVIRONMENT=production

# Flutterwave (Live)
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_LIVE-...
FLUTTERWAVE_SECRET_KEY=FLWSECK_LIVE-...
FLUTTERWAVE_WEBHOOK_SECRET=your-webhook-secret

# Firebase
FIREBASE_PROJECT_ID=agrisupply-production
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@agrisupply.iam.gserviceaccount.com

# SMS (Africa's Talking)
AFRICASTALKING_API_KEY=your-production-key
AFRICASTALKING_USERNAME=agrisupply
AFRICASTALKING_SENDER_ID=AgriSupply
```

### Flutter Production Config

```dart
// lib/config/env.dart
class Env {
  static const String apiBaseUrl = 'https://api.agrisupply.ug/api/v1';
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  static const String googleMapsApiKey = 'your-maps-key';
}
```

---

## Monitoring & Logging

### Setup Sentry (Error Tracking)

1. **Create Sentry Project**
   - Sign up at [sentry.io](https://sentry.io)
   - Create new project

2. **Backend Integration**
   ```bash
   npm install @sentry/node
   ```
   ```javascript
   // src/index.js
   const Sentry = require('@sentry/node');
   Sentry.init({ dsn: process.env.SENTRY_DSN });
   ```

3. **Flutter Integration**
   ```yaml
   # pubspec.yaml
   dependencies:
     sentry_flutter: ^7.0.0
   ```

### Setup Logging

1. **Winston Logs** (Already configured)
   - Logs stored in `/logs` directory
   - Configure log rotation for production

2. **CloudWatch (AWS)**
   ```bash
   npm install winston-cloudwatch
   ```

### Health Checks

The API includes a health endpoint:
```bash
curl https://api.agrisupply.ug/health
```

---

## Troubleshooting

### Common Issues

#### 1. Database Connection Failed
```
Error: Connection refused
```
**Solution:** Check Supabase URL and service role key

#### 2. Payment Callback Not Received
```
Error: Callback timeout
```
**Solution:** 
- Verify callback URL is publicly accessible
- Check SSL certificate is valid
- Ensure firewall allows incoming webhooks

#### 3. Push Notifications Not Working
```
Error: Invalid FCM credentials
```
**Solution:**
- Download new Firebase service account JSON
- Update FIREBASE_PRIVATE_KEY in environment

#### 4. Image Upload Failed
```
Error: Storage bucket not found
```
**Solution:** Create storage buckets in Supabase Dashboard

### Performance Optimization

1. **Enable Compression**
   - Already configured in Express middleware

2. **Configure CDN**
   - Use Cloudflare for static assets
   - Configure proper cache headers

3. **Database Indexes**
   - All indexes included in schema.sql
   - Monitor slow queries in Supabase

### Security Checklist

- [ ] HTTPS enabled with valid SSL
- [ ] Environment variables secured
- [ ] Rate limiting enabled
- [ ] CORS configured for production domains only
- [ ] Helmet security headers enabled
- [ ] JWT secrets rotated periodically
- [ ] Database RLS policies active
- [ ] Payment webhooks verified
- [ ] API keys restricted by IP/domain

---

## Support

For deployment assistance:
- 📧 Email: devops@agrisupply.ug
- 📚 Docs: docs.agrisupply.ug
- 💬 Discord: discord.gg/agrisupply
