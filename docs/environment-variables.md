# Environment Variables Reference
# Complete list of all environment variables for AgriSupply

# =============================================================================
# APPLICATION SETTINGS
# =============================================================================

# Application name
APP_NAME=AgriSupply

# Environment (development, staging, production)
NODE_ENV=development

# Server port
PORT=3000

# API version prefix
API_VERSION=v1

# Base URL for the API
API_BASE_URL=http://localhost:3000/api/v1

# Frontend URL (for CORS and email links)
FRONTEND_URL=http://localhost:3000

# =============================================================================
# DATABASE - SUPABASE
# =============================================================================

# Supabase project URL
SUPABASE_URL=https://your-project.supabase.co

# Supabase anonymous/public key (safe for client-side)
SUPABASE_ANON_KEY=your-anon-key

# Supabase service role key (server-side only - never expose!)
SUPABASE_SERVICE_KEY=your-service-key

# Direct database connection (optional, for migrations)
DATABASE_URL=postgresql://postgres:[password]@db.your-project.supabase.co:5432/postgres

# =============================================================================
# AUTHENTICATION
# =============================================================================

# JWT secret for signing tokens (generate a strong random string)
JWT_SECRET=your-super-secret-jwt-key-min-32-characters

# JWT token expiration
JWT_EXPIRES_IN=7d

# Refresh token expiration
JWT_REFRESH_EXPIRES_IN=30d

# Password hashing rounds
BCRYPT_ROUNDS=12

# OTP expiration in minutes
OTP_EXPIRES_IN=10

# =============================================================================
# PAYMENT PROVIDERS
# =============================================================================

# MTN Mobile Money Uganda
MTN_API_URL=https://sandbox.momodeveloper.mtn.com
MTN_API_KEY=your-mtn-api-key
MTN_API_SECRET=your-mtn-api-secret
MTN_SUBSCRIPTION_KEY=your-mtn-subscription-key
MTN_ENVIRONMENT=sandbox
MTN_CALLBACK_URL=https://api.agrisupply.ug/api/v1/payments/callback/mtn

# Airtel Money Uganda
AIRTEL_API_URL=https://openapiuat.airtel.africa
AIRTEL_API_KEY=your-airtel-api-key
AIRTEL_API_SECRET=your-airtel-api-secret
AIRTEL_ENVIRONMENT=sandbox
AIRTEL_CALLBACK_URL=https://api.agrisupply.ug/api/v1/payments/callback/airtel

# Flutterwave (Card Payments)
FLUTTERWAVE_PUBLIC_KEY=your-flutterwave-public-key
FLUTTERWAVE_SECRET_KEY=your-flutterwave-secret-key
FLUTTERWAVE_ENCRYPTION_KEY=your-flutterwave-encryption-key
FLUTTERWAVE_WEBHOOK_SECRET=your-webhook-secret
FLUTTERWAVE_REDIRECT_URL=https://app.agrisupply.ug/payment/callback

# =============================================================================
# AI SERVICES
# =============================================================================

# OpenAI API
OPENAI_API_KEY=your-openai-api-key
OPENAI_ORGANIZATION=your-org-id
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_MAX_TOKENS=1000

# AI usage limits per user per day
AI_DAILY_CHAT_LIMIT=50
AI_DAILY_IMAGE_LIMIT=10

# =============================================================================
# FILE STORAGE
# =============================================================================

# Supabase Storage bucket names
STORAGE_BUCKET_PRODUCTS=product-images
STORAGE_BUCKET_AVATARS=user-avatars
STORAGE_BUCKET_REVIEWS=review-images

# Max file upload size in MB
MAX_FILE_SIZE_MB=10

# Allowed image types
ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/webp

# =============================================================================
# EMAIL SERVICE
# =============================================================================

# Email provider (sendgrid, mailgun, smtp)
EMAIL_PROVIDER=sendgrid

# SendGrid
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_FROM_EMAIL=noreply@agrisupply.ug
SENDGRID_FROM_NAME=AgriSupply

# SMTP (alternative)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@agrisupply.ug

# =============================================================================
# PUSH NOTIFICATIONS
# =============================================================================

# Firebase Cloud Messaging
FCM_PROJECT_ID=your-firebase-project-id
FCM_PRIVATE_KEY=your-private-key
FCM_CLIENT_EMAIL=your-service-account-email
FCM_DATABASE_URL=https://your-project.firebaseio.com

# =============================================================================
# SMS SERVICE
# =============================================================================

# SMS provider (africas_talking, twilio)
SMS_PROVIDER=africas_talking

# Africa's Talking
AT_API_KEY=your-africas-talking-api-key
AT_USERNAME=your-username
AT_SENDER_ID=AgriSupply

# Twilio (alternative)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# =============================================================================
# CACHING - REDIS
# =============================================================================

# Redis connection
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
REDIS_DB=0

# Cache TTL in seconds
CACHE_TTL_DEFAULT=3600
CACHE_TTL_PRODUCTS=1800
CACHE_TTL_USER=900

# =============================================================================
# RATE LIMITING
# =============================================================================

# General API rate limit (requests per minute)
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# Auth endpoints rate limit
AUTH_RATE_LIMIT_MAX=10

# AI endpoints rate limit (per hour)
AI_RATE_LIMIT_MAX=20

# =============================================================================
# LOGGING
# =============================================================================

# Log level (error, warn, info, debug)
LOG_LEVEL=info

# Log format (json, pretty)
LOG_FORMAT=json

# Enable request logging
ENABLE_REQUEST_LOGGING=true

# External logging service
LOGTAIL_SOURCE_TOKEN=your-logtail-token
SENTRY_DSN=your-sentry-dsn

# =============================================================================
# MONITORING
# =============================================================================

# Health check endpoint
HEALTH_CHECK_PATH=/health

# Metrics endpoint
METRICS_PATH=/metrics

# Enable Prometheus metrics
ENABLE_PROMETHEUS=true

# =============================================================================
# SECURITY
# =============================================================================

# CORS allowed origins (comma-separated)
CORS_ORIGINS=http://localhost:3000,https://app.agrisupply.ug

# Helmet security headers
ENABLE_HELMET=true

# Trust proxy (for reverse proxy setups)
TRUST_PROXY=1

# Session secret
SESSION_SECRET=your-session-secret

# =============================================================================
# GEOGRAPHIC SETTINGS
# =============================================================================

# Default country code
DEFAULT_COUNTRY_CODE=UG

# Default currency
DEFAULT_CURRENCY=UGX

# Default timezone
DEFAULT_TIMEZONE=Africa/Kampala

# Supported regions
SUPPORTED_REGIONS=Central,Eastern,Western,Northern

# =============================================================================
# FEATURE FLAGS
# =============================================================================

# Enable/disable features
ENABLE_AI_CHAT=true
ENABLE_AI_IMAGE_ANALYSIS=true
ENABLE_MOBILE_MONEY=true
ENABLE_CARD_PAYMENTS=true
ENABLE_CASH_ON_DELIVERY=true
ENABLE_NOTIFICATIONS=true
ENABLE_REVIEWS=true
ENABLE_FAVORITES=true

# =============================================================================
# DEVELOPMENT
# =============================================================================

# Enable debug mode
DEBUG=false

# Enable API documentation
ENABLE_DOCS=true

# Swagger UI path
DOCS_PATH=/docs

# Seed database on startup
AUTO_SEED=false

# =============================================================================
# DEPLOYMENT
# =============================================================================

# Docker image tag
IMAGE_TAG=latest

# Kubernetes namespace
K8S_NAMESPACE=agrisupply

# Health check interval
HEALTH_CHECK_INTERVAL=30s

# Graceful shutdown timeout
SHUTDOWN_TIMEOUT=30000
