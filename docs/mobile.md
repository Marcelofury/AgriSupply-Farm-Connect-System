# AgriSupply Mobile Documentation (Current System)

## Overview
The mobile app is a Flutter client that uses:
- Provider for state management
- Supabase for auth bootstrap
- REST API integration with backend (/api/v1)

## Current Mobile Architecture

### Entry and App Setup
- mobile/lib/main.dart
  - Initializes Flutter bindings
  - Initializes Supabase with app config
  - Registers providers:
    - AuthProvider
    - CartProvider
    - ProductProvider
    - OrderProvider
    - NotificationProvider
  - Starts at SplashScreen

### Configuration
- mobile/lib/config/app_config.dart
  - Supabase URL/Anon key
  - API base URL
  - app constants
- mobile/lib/config/routes.dart
  - Route constants and route generation
- mobile/lib/config/theme.dart
  - app themes

### Localization
- mobile/lib/l10n/app_en.arb
- mobile/lib/l10n/app_lg.arb
- generated localization files

### Models
- user_model.dart
- product_model.dart
- order_model.dart
- cart_model.dart
- review_model.dart
- notification_model.dart

### Providers
- auth_provider.dart
- product_provider.dart
- cart_provider.dart
- order_provider.dart
- notification_provider.dart
- user_provider.dart

### Services
- api_service.dart
- auth_service.dart
- product_service.dart
- order_service.dart
- payment_service.dart
- notification_service.dart
- ai_service.dart
- user_service.dart
- location_service.dart
- storage_service.dart

### Screens by Domain

Auth screens:
- mobile/lib/screens/auth/login_screen.dart
- mobile/lib/screens/auth/register_screen.dart
- mobile/lib/screens/auth/otp_verification_screen.dart
- mobile/lib/screens/auth/forgot_password_screen.dart

Buyer screens:
- buyer_home_screen.dart
- search_screen.dart
- product_detail_screen.dart
- cart_screen.dart
- checkout_screen.dart
- buyer_orders_screen.dart
- order_tracking_screen.dart
- payment_methods_screen.dart
- buyer_profile_screen.dart
- delivery_addresses_screen.dart
- about_screen.dart
- help_support_screen.dart

Farmer screens:
- farmer_dashboard_screen.dart
- add_product_screen.dart
- farmer_products_screen.dart
- farmer_orders_screen.dart
- farmer_analytics_screen.dart
- farmer_profile_screen.dart
- ai_assistant_screen.dart
- premium_screen.dart

Admin screens:
- admin_dashboard_screen.dart
- user_management_screen.dart
- product_management_screen.dart
- order_management_screen.dart
- analytics_screen.dart

Common screens:
- notifications_screen.dart
- help_support_screen.dart

### Shared Widgets
- custom_button.dart
- custom_text_field.dart
- product_card.dart
- search_bar_widget.dart
- quantity_selector.dart
- rating_stars.dart
- order_status_badge.dart
- loading_overlay.dart
- category_chip.dart

## Runtime Request Flow
1. Screen triggers action.
2. Provider updates loading/state.
3. Service sends API request.
4. Backend responds.
5. Provider updates state.
6. Screen rebuilds UI.

## Authentication and Role Routing
- Login/register actions in auth screens.
- Auth state in auth_provider.
- Route generation in config/routes.dart.
- Role-specific dashboards:
  - Buyer -> buyer home
  - Farmer -> farmer dashboard
  - Admin -> admin dashboard

## API Integration
- Base URL from app_config.dart.
- Bearer token attached by API/auth service flow.
- Main modules consumed:
  - auth
  - users
  - products
  - orders
  - payments
  - notifications
  - ai
  - admin

## Mobile-to-Backend Feature Mapping
- Browse/search -> product_service -> /products
- Checkout/place order -> order_service -> /orders
- Payment -> payment_service -> /payments
- Tracking -> order_service -> /orders/:id/tracking
- Reviews -> product_service -> /products/:id/reviews

## Build/Run
From mobile folder:
- flutter pub get
- flutter run
- flutter build apk --release

## Configuration Consistency Checklist
- app_config apiBaseUrl points to deployed backend.
- Supabase URL/key are valid for target environment.
- Payment callbacks configured on backend side.
- Route names match screens used by navigation.
