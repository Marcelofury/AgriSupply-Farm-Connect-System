# Sequence-Based Feature Presentation Guide

## Purpose
Use this guide to present the code section feature-by-feature, aligned to the sequence diagrams already prepared.

## How to Use During Presentation
For each feature:
1. State the business goal.
2. Show frontend trigger screen.
3. Trace provider/service call.
4. Show backend controller logic.
5. Mention database tables updated.
6. Show success path and one failure path.

## Backend Communication Architecture (Across All Sequences)
This is the exact request path students should explain for every sequence:
1. Flutter Screen (user action)
2. Provider (state + trigger)
3. Service (HTTP request)
4. Route file (endpoint + middleware chain)
5. Middleware (auth/role/validation)
6. Controller (business logic)
7. Service layer (external APIs where needed)
8. Database operations (Supabase/PostgreSQL)
9. JSON response to frontend

### Core Backend Files to Show First
- backend/src/index.js (API mounting and base paths)
- backend/src/routes/authRoutes.js
- backend/src/routes/productRoutes.js
- backend/src/routes/orderRoutes.js
- backend/src/routes/paymentRoutes.js
- backend/src/routes/adminRoutes.js
- backend/src/middleware/authMiddleware.js
- backend/src/middleware/errorMiddleware.js
- backend/src/controllers/authController.js
- backend/src/controllers/productController.js
- backend/src/controllers/orderController.js
- backend/src/controllers/paymentController.js
- backend/src/controllers/adminController.js
- backend/src/services/marzpayService.js

### Sequence-to-Backend Communication Map

#### Register Sequence
- Frontend call: POST /api/v1/auth/register
- Route chain: authRoutes -> authValidators.register -> handleValidation -> authController.register
- Backend files: backend/src/routes/authRoutes.js, backend/src/controllers/authController.js
- Data operations: users profile creation, optional notification_preferences setup

#### Login Sequence
- Frontend call: POST /api/v1/auth/login
- Route chain: authRoutes -> authValidators.login -> handleValidation -> authController.login
- Backend files: backend/src/routes/authRoutes.js, backend/src/controllers/authController.js
- Data operations: users lookup and last_login_at update

#### Browse/Search Sequence
- Frontend calls: GET /api/v1/products, GET /api/v1/products/search
- Route chain: productRoutes -> optionalAuth -> productController.getProducts/searchProducts
- Backend files: backend/src/routes/productRoutes.js, backend/src/controllers/productController.js
- Data operations: products read with filters/pagination

#### Checkout/Place Order Sequence
- Frontend call: POST /api/v1/orders
- Route chain: orderRoutes -> authenticate -> orderValidators.create -> handleValidation -> orderController.createOrder
- Backend files: backend/src/routes/orderRoutes.js, backend/src/controllers/orderController.js
- Data operations: orders insert, order_items insert, products quantity update, order_status_history insert, notifications insert

#### Payment Sequence
- Frontend call: POST /api/v1/payments/initiate
- Callback: POST /api/v1/payments/marzpay/callback (also mtn/airtel/card callbacks)
- Route chain: paymentRoutes -> authenticate -> paymentValidators.initiate -> handleValidation -> paymentController.initiatePayment
- Backend files: backend/src/routes/paymentRoutes.js, backend/src/controllers/paymentController.js, backend/src/services/marzpayService.js
- Data operations: payments insert/update, orders.payment_status update

#### Tracking Sequence
- Frontend calls: GET /api/v1/orders/:id, GET /api/v1/orders/:id/tracking, GET /api/v1/orders/:id/history
- Route chain: orderRoutes -> authenticate -> id validation -> orderController methods
- Backend files: backend/src/routes/orderRoutes.js, backend/src/controllers/orderController.js
- Data operations: orders and order_status_history reads

#### Review Sequence
- Frontend call: POST /api/v1/products/:id/reviews
- Route chain: productRoutes -> authenticate -> productValidators.review -> handleValidation -> productController.addReview
- Backend files: backend/src/routes/productRoutes.js, backend/src/controllers/productController.js
- Data operations: product_reviews insert, products rating aggregation update

#### Farmer Product Management Sequence
- Frontend calls: POST /api/v1/products, PUT /api/v1/products/:id
- Route chain: productRoutes -> authenticate -> requireFarmer -> validation -> productController.createProduct/updateProduct
- Backend files: backend/src/routes/productRoutes.js, backend/src/controllers/productController.js
- Data operations: products create/update, optional image upload handling

#### Farmer Fulfillment Sequence
- Frontend calls: PUT /api/v1/orders/:id/status, POST /api/v1/orders/:id/confirm, /ship, /deliver
- Route chain: orderRoutes -> authenticate (+requireFarmer where applicable) -> validators -> orderController
- Backend files: backend/src/routes/orderRoutes.js, backend/src/controllers/orderController.js
- Data operations: order_items status update, orders status update, order_status_history insert, notifications insert

#### Admin Moderation Sequence
- Frontend calls: /api/v1/admin/users, /products, /orders, /analytics/*
- Route chain: adminRoutes (router.use(authenticate, requireAdmin)) -> validators -> adminController methods
- Backend files: backend/src/routes/adminRoutes.js, backend/src/controllers/adminController.js, backend/src/middleware/authMiddleware.js
- Data operations: users/products/orders/payments moderation and analytics queries

---

## Feature 1: Register Account
### Sequence
Register sequence diagram.

### Business Goal
Allow new users to create an account and profile.

### What to Show
- Frontend form submission flow
- Auth service call
- Backend registration and profile creation

### Files to Open
- mobile/lib/screens/auth/register_screen.dart
- mobile/lib/providers/auth_provider.dart
- mobile/lib/services/auth_service.dart
- backend/src/controllers/authController.js

### Data Impact
- users
- notification_preferences (if initialized on registration)

### Demo Script
1. User enters details and selects role.
2. App validates input and sends register request.
3. Backend creates auth user and profile.
4. App receives token/profile and routes user accordingly.

### Likely Questions
- Where is role assigned?
- What happens if email already exists?
- How is profile created after auth?

---

## Feature 2: Login and Role Routing
### Sequence
Login sequence diagram.

### Business Goal
Authenticate users and route them to Buyer, Farmer, or Admin dashboard.

### What to Show
- Login screen action
- Auth provider state update
- Backend auth verification and profile lookup

### Files to Open
- mobile/lib/screens/auth/login_screen.dart
- mobile/lib/providers/auth_provider.dart
- mobile/lib/config/routes.dart
- backend/src/controllers/authController.js

### Data Impact
- users.last_login_at

### Demo Script
1. User logs in with credentials.
2. Backend verifies credentials and returns profile.
3. App checks role and navigates to role-specific dashboard.

### Likely Questions
- Where is route decision made?
- How is suspended user blocked?
- Where is token stored/used?

---

## Feature 3: Browse and Search Products
### Sequence
Browse/Search sequence diagram.

### Business Goal
Help buyers discover products quickly.

### What to Show
- Search input and result rendering
- Product provider/service fetching product list
- Backend filtering logic

### Files to Open
- mobile/lib/screens/buyer/search_screen.dart
- mobile/lib/screens/buyer/buyer_home_screen.dart
- mobile/lib/providers/product_provider.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

### Data Impact
- products (read)

### Demo Script
1. Buyer searches by keyword/category.
2. App fetches filtered products.
3. Results display cards with price/category/rating info.

### Likely Questions
- Is search server-side or client-side?
- How do you filter by category/price?

---

## Feature 4: Add to Cart
### Sequence
Add-to-cart sequence diagram.

### Business Goal
Allow buyers to stage products before checkout.

### What to Show
- Product detail/cart action
- Cart provider updates
- Cart API/storage sync

### Files to Open
- mobile/lib/screens/buyer/product_detail_screen.dart
- mobile/lib/screens/buyer/cart_screen.dart
- mobile/lib/providers/cart_provider.dart
- mobile/lib/services/order_service.dart or cart service logic
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

### Data Impact
- cart_items (if persisted)
- local/provider cart state

### Demo Script
1. Buyer adds item from product detail.
2. Cart state updates quantity and subtotal.
3. Cart screen reflects live totals.

### Likely Questions
- How are duplicate cart items handled?
- Where are totals recalculated?

---

## Feature 5: Checkout and Place Order
### Sequence
Checkout and Place Order sequence diagrams.

### Business Goal
Convert cart into an order with delivery details.

### What to Show
- Checkout page confirmation
- Order provider/service call
- Backend stock validation and order creation

### Files to Open
- mobile/lib/screens/buyer/checkout_screen.dart
- mobile/lib/providers/order_provider.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

### Data Impact
- orders
- order_items
- products.quantity_available
- order_status_history
- notifications

### Demo Script
1. Buyer confirms address and payment method.
2. Backend validates stock and creates order + order items.
3. Product quantities are adjusted.
4. Farmers are notified of new order.

### Likely Questions
- How do you prevent overselling stock?
- Is order creation transactional?
- What happens if items insert fails?

---

## Feature 6: Payment Initiation and Callback
### Sequence
Payment initiation + webhook sequence diagram.

### Business Goal
Collect payment and update order payment status reliably.

### What to Show
- Payment method selection
- Backend payment initiation
- Callback/webhook status update

### Files to Open
- mobile/lib/screens/buyer/payment_methods_screen.dart
- mobile/lib/services/payment_service.dart
- backend/src/routes/paymentRoutes.js
- backend/src/controllers/paymentController.js
- backend/src/services/marzpayService.js

### Data Impact
- payments
- orders.payment_status

### Demo Script
1. Buyer triggers payment from app.
2. Backend sends payment request to gateway.
3. Gateway callback confirms success/failure.
4. Backend updates payment and order status.

### Likely Questions
- Why callback is necessary?
- How do you handle pending/failed payments?
- How do you avoid duplicate status updates?

---

## Feature 7: Order Tracking (Buyer)
### Sequence
Order tracking sequence diagram.

### Business Goal
Give buyer transparent fulfillment progress.

### What to Show
- Tracking screen timeline
- API call for order and status history

### Files to Open
- mobile/lib/screens/buyer/order_tracking_screen.dart
- mobile/lib/screens/buyer/buyer_orders_screen.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

### Data Impact
- orders (read)
- order_status_history (read)

### Demo Script
1. Buyer opens order details.
2. App fetches status timeline.
3. Screen displays latest stage and history.

### Likely Questions
- Who can see a specific order?
- Where does status history come from?

---

## Feature 8: Submit Review
### Sequence
Submit review sequence diagram.

### Business Goal
Allow post-delivery feedback and trust building.

### What to Show
- Rating/comment submission
- Backend review insert and product rating update

### Files to Open
- mobile/lib/screens/buyer/product_detail_screen.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

### Data Impact
- product_reviews
- products.rating / total_reviews

### Demo Script
1. Buyer submits rating and comment.
2. Review is saved.
3. Product aggregate rating is updated.

### Likely Questions
- Can user review without purchase?
- How do you recalculate average rating?

---

## Feature 9: Farmer Add/Edit Product
### Sequence
Farmer product listing sequence diagram.

### Business Goal
Enable farmers to publish and maintain product inventory.

### What to Show
- Add/Edit product form
- Optional image upload
- Backend product save/update

### Files to Open
- mobile/lib/screens/farmer/add_product_screen.dart
- mobile/lib/screens/farmer/farmer_products_screen.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

### Data Impact
- products
- storage references (images)

### Demo Script
1. Farmer fills product details and submits.
2. App sends payload and media URLs.
3. Product appears in farmer product list by status.

### Likely Questions
- How do you validate product fields?
- How do draft/pending/active states work?

---

## Feature 10: Farmer Order Fulfillment
### Sequence
Farmer order fulfillment sequence diagram.

### Business Goal
Let farmers process buyer orders through lifecycle stages.

### What to Show
- Farmer orders tabs and status actions
- Backend status updates and buyer notifications

### Files to Open
- mobile/lib/screens/farmer/farmer_orders_screen.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

### Data Impact
- order_items.status
- orders.status
- order_status_history
- notifications

### Demo Script
1. Farmer opens pending orders.
2. Farmer confirms, ships, or marks delivered.
3. Buyer receives updated tracking status.

### Likely Questions
- Can farmer update any order?
- How do partial/multi-farmer orders behave?

---

## Feature 11: Admin Moderation
### Sequence
Admin moderation sequence diagram.

### Business Goal
Maintain quality, trust, and platform compliance.

### What to Show
- Admin dashboard tabs
- User/product/order management screens
- Backend moderation endpoints

### Files to Open
- mobile/lib/screens/admin/admin_dashboard_screen.dart
- mobile/lib/screens/admin/user_management_screen.dart
- mobile/lib/screens/admin/product_management_screen.dart
- mobile/lib/screens/admin/order_management_screen.dart
- backend/src/routes/adminRoutes.js
- backend/src/middleware/authMiddleware.js
- backend/src/controllers/adminController.js

### Data Impact
- users (suspend/verify)
- products (approve/reject)
- orders (admin notes/interventions)

### Demo Script
1. Admin reviews flagged/pending records.
2. Admin takes moderation action.
3. Status changes become visible to users.

### Likely Questions
- How is admin authorization enforced?
- Are admin actions auditable?

---

## Final 10-Minute Code Presentation Order
1. App entry and providers
2. Routes and role-based navigation
3. Register/login feature trace
4. Buyer order pipeline (search -> cart -> checkout -> order)
5. Payment callback reliability
6. Farmer fulfillment flow
7. Admin moderation controls
8. Security/error handling summary

## Closing Line
The project is structured as Screen -> Provider -> Service -> API Controller -> Database/External Service, and each sequence diagram maps directly to one feature path in code.