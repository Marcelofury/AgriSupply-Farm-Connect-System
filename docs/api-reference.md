# AgriSupply API Reference

Complete API reference documentation for the AgriSupply backend.

## Base URL

```
Production: https://api.agrisupply.ug/api/v1
Staging: https://staging-api.agrisupply.ug/api/v1
Local: http://localhost:3000/api/v1
```

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <access_token>
```

---

## Authentication Endpoints

### Register User

```http
POST /auth/register
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securePassword123",
  "fullName": "John Doe",
  "phone": "+256701234567",
  "role": "buyer",
  "region": "Central",
  "district": "Kampala"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | Valid email address |
| password | string | Yes | Min 8 characters |
| fullName | string | Yes | User's full name |
| phone | string | Yes | Ugandan phone number (+256) |
| role | string | Yes | `buyer`, `farmer`, or `admin` |
| region | string | No | Ugandan region |
| district | string | No | Ugandan district |

**Response: 201 Created**
```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "data": {
    "user": {
      "id": "uuid",
      "email": "john@example.com",
      "fullName": "John Doe",
      "role": "buyer"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### Login

```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "john@example.com",
      "fullName": "John Doe",
      "role": "buyer",
      "phone": "+256701234567",
      "avatar": "https://storage.supabase.co/...",
      "region": "Central",
      "district": "Kampala",
      "isVerified": true
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### Refresh Token

```http
POST /auth/refresh-token
```

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### Logout

```http
POST /auth/logout
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### Forgot Password

```http
POST /auth/forgot-password
```

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Password reset link sent to your email"
}
```

---

### Reset Password

```http
POST /auth/reset-password
```

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "password": "newSecurePassword123"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Password reset successful"
}
```

---

### Verify OTP

```http
POST /auth/verify-otp
```

**Request Body:**
```json
{
  "phone": "+256701234567",
  "otp": "123456"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Phone verified successfully"
}
```

---

## User Endpoints

### Get Current User

```http
GET /users/me
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "john@example.com",
    "fullName": "John Doe",
    "phone": "+256701234567",
    "role": "buyer",
    "avatar": "https://...",
    "region": "Central",
    "district": "Kampala",
    "address": "Plot 123, Kampala Road",
    "isVerified": true,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

---

### Update Profile

```http
PUT /users/me
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body:**
```
fullName: John Updated
phone: +256707654321
region: Western
district: Mbarara
address: New Address
avatar: [file]
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": { /* updated user object */ }
}
```

---

### Get Farmer Profile

```http
GET /users/farmers/:farmerId
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "fullName": "Farmer Jane",
    "avatar": "https://...",
    "region": "Eastern",
    "district": "Jinja",
    "rating": 4.7,
    "totalProducts": 15,
    "totalSales": 234,
    "followerCount": 45,
    "isFollowing": true,
    "createdAt": "2023-06-01T00:00:00Z"
  }
}
```

---

### Follow Farmer

```http
POST /users/farmers/:farmerId/follow
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Now following farmer"
}
```

---

### Unfollow Farmer

```http
DELETE /users/farmers/:farmerId/follow
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Unfollowed farmer"
}
```

---

## Product Endpoints

### List Products

```http
GET /products
Authorization: Bearer <token> (optional)
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number (default: 1) |
| limit | number | Items per page (default: 20, max: 100) |
| category | string | Filter by category |
| region | string | Filter by region |
| district | string | Filter by district |
| minPrice | number | Minimum price |
| maxPrice | number | Maximum price |
| search | string | Search query |
| sortBy | string | `price`, `createdAt`, `rating` |
| order | string | `asc` or `desc` |

**Response: 200 OK**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Fresh Organic Matooke",
      "description": "Fresh matooke from Mbarara farms",
      "price": 35000,
      "unit": "bunch",
      "category": "fruits_vegetables",
      "images": ["https://..."],
      "stock": 50,
      "isOrganic": true,
      "harvestDate": "2024-01-10",
      "farmer": {
        "id": "uuid",
        "fullName": "Farmer Jane",
        "rating": 4.7
      },
      "rating": 4.5,
      "reviewCount": 23,
      "region": "Western",
      "district": "Mbarara"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 156,
    "totalPages": 8
  }
}
```

---

### Get Product Details

```http
GET /products/:productId
Authorization: Bearer <token> (optional)
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Fresh Organic Matooke",
    "description": "Fresh matooke from Mbarara farms...",
    "price": 35000,
    "unit": "bunch",
    "category": "fruits_vegetables",
    "images": [
      "https://storage.supabase.co/...",
      "https://storage.supabase.co/..."
    ],
    "stock": 50,
    "isOrganic": true,
    "harvestDate": "2024-01-10",
    "expiryDate": "2024-01-25",
    "minOrderQuantity": 1,
    "maxOrderQuantity": 20,
    "farmer": {
      "id": "uuid",
      "fullName": "Farmer Jane",
      "phone": "+256701234567",
      "avatar": "https://...",
      "rating": 4.7,
      "region": "Western",
      "district": "Mbarara"
    },
    "rating": 4.5,
    "reviewCount": 23,
    "region": "Western",
    "district": "Mbarara",
    "location": {
      "latitude": 0.6070,
      "longitude": 30.6545
    },
    "isFavorite": false,
    "createdAt": "2024-01-08T10:00:00Z",
    "updatedAt": "2024-01-10T15:30:00Z"
  }
}
```

---

### Create Product (Farmer Only)

```http
POST /products
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body:**
```
name: Fresh Organic Matooke
description: Fresh matooke from our farms
price: 35000
unit: bunch
category: fruits_vegetables
stock: 50
isOrganic: true
harvestDate: 2024-01-10
expiryDate: 2024-01-25
minOrderQuantity: 1
maxOrderQuantity: 20
images: [files]
```

**Response: 201 Created**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": { /* product object */ }
}
```

---

### Update Product (Farmer Only)

```http
PUT /products/:productId
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Product updated successfully",
  "data": { /* updated product object */ }
}
```

---

### Delete Product (Farmer Only)

```http
DELETE /products/:productId
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Product deleted successfully"
}
```

---

### Add to Favorites

```http
POST /products/:productId/favorite
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Added to favorites"
}
```

---

### Remove from Favorites

```http
DELETE /products/:productId/favorite
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Removed from favorites"
}
```

---

### Get Product Reviews

```http
GET /products/:productId/reviews
Authorization: Bearer <token> (optional)
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number |
| limit | number | Items per page |

**Response: 200 OK**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "rating": 5,
      "comment": "Excellent quality matooke!",
      "images": ["https://..."],
      "user": {
        "id": "uuid",
        "fullName": "Happy Buyer",
        "avatar": "https://..."
      },
      "createdAt": "2024-01-12T14:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 23,
    "totalPages": 3
  }
}
```

---

### Add Product Review

```http
POST /products/:productId/reviews
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body:**
```
rating: 5
comment: Excellent quality matooke!
images: [files]
```

**Response: 201 Created**
```json
{
  "success": true,
  "message": "Review added successfully",
  "data": { /* review object */ }
}
```

---

## Order Endpoints

### Create Order

```http
POST /orders
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "items": [
    {
      "productId": "uuid",
      "quantity": 2
    },
    {
      "productId": "uuid",
      "quantity": 1
    }
  ],
  "deliveryAddress": "Plot 123, Kampala Road, Kampala",
  "deliveryNotes": "Call before delivery",
  "paymentMethod": "mtn_mobile_money"
}
```

**Response: 201 Created**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "id": "uuid",
    "orderNumber": "AGR-2024-001234",
    "status": "pending",
    "items": [...],
    "subtotal": 70000,
    "deliveryFee": 5000,
    "total": 75000,
    "deliveryAddress": "Plot 123, Kampala Road, Kampala",
    "paymentMethod": "mtn_mobile_money",
    "paymentStatus": "pending",
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

---

### Get Orders

```http
GET /orders
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number |
| limit | number | Items per page |
| status | string | Filter by status |

**Response: 200 OK**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "orderNumber": "AGR-2024-001234",
      "status": "delivered",
      "itemCount": 3,
      "total": 75000,
      "createdAt": "2024-01-15T10:00:00Z",
      "deliveredAt": "2024-01-16T14:30:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Get Order Details

```http
GET /orders/:orderId
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "orderNumber": "AGR-2024-001234",
    "status": "processing",
    "items": [
      {
        "id": "uuid",
        "product": {
          "id": "uuid",
          "name": "Fresh Matooke",
          "images": ["https://..."],
          "farmer": {
            "id": "uuid",
            "fullName": "Farmer Jane"
          }
        },
        "quantity": 2,
        "price": 35000,
        "total": 70000
      }
    ],
    "subtotal": 70000,
    "deliveryFee": 5000,
    "total": 75000,
    "deliveryAddress": "Plot 123, Kampala Road",
    "deliveryNotes": "Call before delivery",
    "paymentMethod": "mtn_mobile_money",
    "paymentStatus": "completed",
    "statusHistory": [
      {
        "status": "pending",
        "timestamp": "2024-01-15T10:00:00Z"
      },
      {
        "status": "confirmed",
        "timestamp": "2024-01-15T10:05:00Z"
      },
      {
        "status": "processing",
        "timestamp": "2024-01-15T11:00:00Z"
      }
    ],
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

---

### Cancel Order

```http
POST /orders/:orderId/cancel
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "reason": "Changed my mind"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Order cancelled successfully"
}
```

---

### Update Order Status (Farmer Only)

```http
PUT /orders/:orderId/status
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "status": "shipped",
  "note": "Package handed to delivery partner"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Order status updated"
}
```

---

## Payment Endpoints

### Initiate Payment

```http
POST /payments/initiate
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "orderId": "uuid",
  "paymentMethod": "mtn_mobile_money",
  "phoneNumber": "+256771234567"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "paymentId": "uuid",
    "status": "pending",
    "transactionRef": "MTN-123456789",
    "message": "Please approve the payment on your phone"
  }
}
```

For card payments:
```json
{
  "success": true,
  "data": {
    "paymentId": "uuid",
    "checkoutUrl": "https://checkout.flutterwave.com/...",
    "status": "pending"
  }
}
```

---

### Check Payment Status

```http
GET /payments/:paymentId/status
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "paymentId": "uuid",
    "status": "completed",
    "amount": 75000,
    "currency": "UGX",
    "paymentMethod": "mtn_mobile_money",
    "transactionRef": "MTN-123456789",
    "completedAt": "2024-01-15T10:05:00Z"
  }
}
```

---

### Payment Callback (Webhook)

```http
POST /payments/callback
```

Called by payment providers to update payment status.

---

## AI Endpoints

### Chat with AI Assistant

```http
POST /ai/chat
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "message": "How do I grow tomatoes in Uganda?",
  "sessionId": "uuid" // optional, for continuing conversation
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "sessionId": "uuid",
    "response": "Growing tomatoes in Uganda is...",
    "suggestions": [
      "What fertilizers should I use?",
      "How to prevent tomato diseases?",
      "Best tomato varieties for Uganda"
    ]
  }
}
```

---

### Analyze Crop Image

```http
POST /ai/analyze-image
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body:**
```
image: [file]
```

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "plantIdentified": "Tomato",
    "healthStatus": "unhealthy",
    "issues": [
      {
        "name": "Late Blight",
        "confidence": 0.89,
        "description": "Fungal disease affecting leaves and fruits",
        "treatment": "Apply copper-based fungicide..."
      }
    ],
    "recommendations": [
      "Remove affected leaves",
      "Improve air circulation",
      "Apply fungicide treatment"
    ]
  }
}
```

---

### Get Market Predictions

```http
GET /ai/market-predictions
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| crop | string | Crop name |
| region | string | Uganda region |

**Response: 200 OK**
```json
{
  "success": true,
  "data": {
    "crop": "Matooke",
    "region": "Central",
    "currentPrice": 35000,
    "predictions": [
      {
        "period": "1 week",
        "predictedPrice": 36000,
        "trend": "up",
        "confidence": 0.82
      },
      {
        "period": "1 month",
        "predictedPrice": 32000,
        "trend": "down",
        "confidence": 0.68
      }
    ],
    "factors": [
      "Harvest season ending",
      "Increased demand during holidays",
      "Weather conditions favorable"
    ]
  }
}
```

---

## Notification Endpoints

### Get Notifications

```http
GET /notifications
Authorization: Bearer <token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number |
| limit | number | Items per page |
| unreadOnly | boolean | Only unread |

**Response: 200 OK**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "type": "order_update",
      "title": "Order Shipped",
      "body": "Your order #AGR-2024-001234 has been shipped",
      "data": {
        "orderId": "uuid"
      },
      "isRead": false,
      "createdAt": "2024-01-15T14:00:00Z"
    }
  ],
  "pagination": { ... },
  "unreadCount": 5
}
```

---

### Mark Notification as Read

```http
PUT /notifications/:notificationId/read
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

### Mark All as Read

```http
PUT /notifications/read-all
Authorization: Bearer <token>
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

---

### Register Device Token

```http
POST /notifications/devices
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "deviceToken": "fcm_token_here",
  "deviceType": "android"
}
```

**Response: 200 OK**
```json
{
  "success": true,
  "message": "Device registered successfully"
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Invalid input data |
| UNAUTHORIZED | 401 | Not authenticated |
| FORBIDDEN | 403 | Not authorized |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource conflict |
| RATE_LIMIT | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

---

## Rate Limiting

- **General endpoints**: 100 requests per minute
- **Auth endpoints**: 10 requests per minute
- **AI endpoints**: 20 requests per hour

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705312800
```

---

## Webhooks

Configure webhooks in your dashboard to receive real-time updates.

### Order Events
- `order.created`
- `order.confirmed`
- `order.shipped`
- `order.delivered`
- `order.cancelled`

### Payment Events
- `payment.completed`
- `payment.failed`
- `payment.refunded`

### Webhook Payload
```json
{
  "event": "order.shipped",
  "timestamp": "2024-01-15T14:00:00Z",
  "data": {
    "orderId": "uuid",
    "orderNumber": "AGR-2024-001234",
    "status": "shipped"
  }
}
```

---

For support, contact api-support@agrisupply.ug
