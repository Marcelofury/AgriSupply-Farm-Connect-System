# AgriSupply UML Explanation Guide (Current System)

## Purpose
This guide explains each UML artifact and how it maps to real files and runtime behavior in this project.

## UML Set Covered
- Use Case Diagram
- DFD Level 0
- ERD
- Post-login Flowchart
- Login Wireframe
- Sequence Diagrams:
  - Register
  - Login
  - Browse/Search Products
  - Add to Cart
  - Checkout
  - Place Order
  - Payment Initiation + Callback/Webhook
  - Order Tracking
  - Submit Review
  - Farmer Add/Edit Product
  - Farmer Order Fulfillment
  - Admin Moderation

---

## 1) Use Case Diagram
### What it shows
Role capabilities for Buyer, Farmer, and Admin.

### File mapping
Frontend role screens:
- mobile/lib/screens/buyer/*
- mobile/lib/screens/farmer/*
- mobile/lib/screens/admin/*

Backend role enforcement:
- backend/src/middleware/authMiddleware.js
- requireFarmer
- requireAdmin

Route groups:
- backend/src/routes/productRoutes.js
- backend/src/routes/orderRoutes.js
- backend/src/routes/adminRoutes.js

---

## 2) DFD Level 0
### What it shows
External entities and top-level data flows around AgriSupply.

### System center file mapping
- backend/src/index.js mounts all route groups.
- backend/src/controllers/* handle domain flows.

### External integrations in current system
- Supabase (DB/Auth/Storage)
- MarzPay + MTN + Airtel + Flutterwave callbacks
- AI route group and controller

Key files:
- backend/src/routes/paymentRoutes.js
- backend/src/services/marzpayService.js
- backend/src/routes/aiRoutes.js

---

## 3) ERD
### What it shows
Data structures and relationships for marketplace operations.

### Core entities used by current flows
- users
- products
- orders
- order_items
- payments
- product_reviews
- notifications
- notification_preferences

### Schema reference
- backend/database/schema.sql

### Where relationships are used in code
- backend/src/controllers/orderController.js
- backend/src/controllers/productController.js
- backend/src/controllers/paymentController.js
- backend/src/controllers/notificationController.js

---

## 4) Post-login Flowchart
### What it shows
Branching after authentication:
- Buyer path: discover -> cart -> checkout -> payment -> tracking -> review
- Farmer path: product management -> order actions -> status updates

### File mapping
Buyer:
- mobile/lib/screens/buyer/buyer_home_screen.dart
- mobile/lib/screens/buyer/cart_screen.dart
- mobile/lib/screens/buyer/checkout_screen.dart
- mobile/lib/screens/buyer/order_tracking_screen.dart

Farmer:
- mobile/lib/screens/farmer/farmer_dashboard_screen.dart
- mobile/lib/screens/farmer/add_product_screen.dart
- mobile/lib/screens/farmer/farmer_orders_screen.dart

Routing:
- mobile/lib/config/routes.dart

---

## 5) Login Wireframe
### What it shows
Entry UI and auth decision point before role-based dashboard navigation.

### File mapping
- mobile/lib/screens/auth/login_screen.dart
- mobile/lib/screens/auth/register_screen.dart
- mobile/lib/screens/auth/forgot_password_screen.dart
- mobile/lib/screens/auth/otp_verification_screen.dart
- mobile/lib/providers/auth_provider.dart
- mobile/lib/services/auth_service.dart

Backend mapping:
- backend/src/routes/authRoutes.js
- backend/src/controllers/authController.js

---

## 6) Sequence Diagrams (Detailed Mapping)

## Register Sequence
Flow:
1. register_screen submits data
2. auth_provider/auth_service sends request
3. POST /auth/register route + validators
4. authController.register creates auth user + profile

Files:
- mobile/lib/screens/auth/register_screen.dart
- mobile/lib/providers/auth_provider.dart
- mobile/lib/services/auth_service.dart
- backend/src/routes/authRoutes.js
- backend/src/controllers/authController.js

## Login Sequence
Flow:
1. login_screen submits credentials
2. auth_service calls POST /auth/login
3. authController.login validates with Supabase and loads profile
4. app routes by role

Files:
- mobile/lib/screens/auth/login_screen.dart
- mobile/lib/providers/auth_provider.dart
- mobile/lib/config/routes.dart
- backend/src/routes/authRoutes.js
- backend/src/controllers/authController.js

## Browse/Search Sequence
Files:
- mobile/lib/screens/buyer/search_screen.dart
- mobile/lib/providers/product_provider.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

## Add to Cart Sequence
Files:
- mobile/lib/screens/buyer/product_detail_screen.dart
- mobile/lib/screens/buyer/cart_screen.dart
- mobile/lib/providers/cart_provider.dart
- mobile/lib/services/order_service.dart

## Checkout and Place Order Sequence
Files:
- mobile/lib/screens/buyer/checkout_screen.dart
- mobile/lib/providers/order_provider.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

## Payment Sequence
Files:
- mobile/lib/screens/buyer/payment_methods_screen.dart
- mobile/lib/services/payment_service.dart
- backend/src/routes/paymentRoutes.js
- backend/src/controllers/paymentController.js
- backend/src/services/marzpayService.js

## Order Tracking Sequence
Files:
- mobile/lib/screens/buyer/order_tracking_screen.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

## Submit Review Sequence
Files:
- mobile/lib/screens/buyer/product_detail_screen.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

## Farmer Add/Edit Product Sequence
Files:
- mobile/lib/screens/farmer/add_product_screen.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

## Farmer Fulfillment Sequence
Files:
- mobile/lib/screens/farmer/farmer_orders_screen.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

## Admin Moderation Sequence
Files:
- mobile/lib/screens/admin/admin_dashboard_screen.dart
- mobile/lib/screens/admin/user_management_screen.dart
- mobile/lib/screens/admin/product_management_screen.dart
- mobile/lib/screens/admin/order_management_screen.dart
- backend/src/routes/adminRoutes.js
- backend/src/controllers/adminController.js

---

## Recommended UML Presentation Order
1. DFD Level 0
2. Use Case
3. ERD
4. Sequence diagrams (auth -> order -> payment -> fulfillment)
5. Post-login flowchart
6. Login wireframe

## Defense Tip
Always explain each UML with this format:
- What this UML type answers
- Which files implement it
- One success path
- One failure/validation path
