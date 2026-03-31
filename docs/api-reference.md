# AgriSupply API Reference (Current System)

## Base URL
- Production: https://agrisupply-farm-connect-system.onrender.com/api/v1
- Local: http://localhost:3000/api/v1

## Auth Header (Protected Endpoints)
Authorization: Bearer <token>

## Response Pattern
Most endpoints return:
- success: boolean
- message: string (when applicable)
- data: object/array (when applicable)

## Route Groups
- /auth
- /users
- /products
- /orders
- /payments
- /notifications
- /ai
- /admin

---

## 1. Authentication

### Public
- POST /auth/register
- POST /auth/login
- POST /auth/google
- POST /auth/phone/send-otp
- POST /auth/phone/verify-otp
- POST /auth/forgot-password
- POST /auth/reset-password
- POST /auth/refresh-token

### Protected
- POST /auth/logout
- PUT /auth/password
- GET /auth/me
- DELETE /auth/account

---

## 2. Users

### Protected
- GET /users/profile
- PUT /users/profile
- POST /users/profile/photo
- DELETE /users/profile/photo
- PUT /users/address
- GET /users/farmers/:id/analytics
- POST /users/farmers/:id/follow
- DELETE /users/farmers/:id/follow
- GET /users/following
- GET /users/followers
- GET /users/statistics

### Public/Optional Auth
- GET /users/farmers
- GET /users/farmers/:id

---

## 3. Products

### Public/Optional Auth
- GET /products
- GET /products/search
- GET /products/featured
- GET /products/categories
- GET /products/:id
- GET /products/:id/reviews

### Protected
- GET /products/favorites/list
- POST /products/:id/favorite
- DELETE /products/:id/favorite
- POST /products/:id/reviews
- PUT /products/:id/reviews/:reviewId
- DELETE /products/:id/reviews/:reviewId

### Farmer Protected
- GET /products/my-products
- POST /products
- PUT /products/:id
- POST /products/:id/images
- DELETE /products/:id/images/:imageIndex
- DELETE /products/:id

---

## 4. Orders

### Buyer/Farmer/Admin Protected
- GET /orders
- GET /orders/:id
- POST /orders
- GET /orders/:id/tracking
- GET /orders/:id/history
- GET /orders/statistics/summary
- POST /orders/:id/cancel
- POST /orders/:id/refund

### Farmer Protected
- GET /orders/farmer
- POST /orders/:id/confirm
- POST /orders/:id/ship

### Farmer/Admin Protected
- PUT /orders/:id/status
- POST /orders/:id/deliver

---

## 5. Payments

### Protected
- POST /payments/initiate
- GET /payments/:orderId/status
- POST /payments/validate-phone
- GET /payments/wallet-balance
- GET /payments/marzpay-transactions
- GET /payments/verify/:transactionId
- POST /payments/:orderId/retry
- POST /payments/:orderId/refund
- GET /payments/history

### Public
- GET /payments/methods

### Public Webhooks
- POST /payments/mtn/callback
- POST /payments/airtel/callback
- POST /payments/marzpay/callback
- POST /payments/card/callback

---

## 6. Notifications

### Protected
- GET /notifications
- GET /notifications/unread-count
- GET /notifications/:id
- PUT /notifications/:id/read
- PUT /notifications/read-all
- DELETE /notifications/:id
- DELETE /notifications
- GET /notifications/preferences
- PUT /notifications/preferences
- POST /notifications/register-device
- DELETE /notifications/unregister-device

---

## 7. AI

### Protected
- POST /ai/chat
- POST /ai/analyze-image
- GET /ai/sessions
- GET /ai/sessions/:sessionId
- DELETE /ai/sessions/:sessionId
- POST /ai/crop-analysis
- GET /ai/farming-tips
- GET /ai/market-predictions
- GET /ai/weather-recommendations
- POST /ai/pest-identification
- POST /ai/disease-diagnosis
- GET /ai/usage

---

## 8. Admin (All Require Admin Role)

- GET /admin/dashboard
- GET /admin/users
- GET /admin/users/:id
- PUT /admin/users/:id
- POST /admin/users/:id/verify
- POST /admin/users/:id/suspend
- POST /admin/users/:id/unsuspend
- DELETE /admin/users/:id
- GET /admin/products
- PUT /admin/products/:id
- DELETE /admin/products/:id
- GET /admin/orders
- PUT /admin/orders/:id
- GET /admin/payments
- POST /admin/payments/:id/refund
- GET /admin/analytics/sales
- GET /admin/analytics/users
- GET /admin/analytics/products
- GET /admin/analytics/regions
- POST /admin/notifications/broadcast
- GET /admin/reports/export
- GET /admin/settings
- PUT /admin/settings

---

## Health and Root
- GET /health
- GET /

## Notes for Integrators
- Validate endpoints and payload constraints with backend validators.
- Webhook endpoints are public by design and must be secured by provider signatures or verification logic.
- For protected routes, always send bearer token from /auth/login or /auth/refresh-token.
