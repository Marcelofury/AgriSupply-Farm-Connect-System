# Backend Field Name Fixes - Deployment Required ⚠️

**Date:** March 10, 2026  
**Priority:** HIGH - Required for mobile app to work with backend

---

## 🔧 Changes Made

### 1. Order Controller - Field Compatibility
**File:** `backend/src/controllers/orderController.js`

**Problem:** Backend expected `shippingAddress` (object), but mobile app sends `deliveryAddress` (string)

**Changes:**
- ✅ Now accepts both `deliveryAddress` (mobile) and `shippingAddress` (web)
- ✅ Normalizes string addresses to object format
- ✅ Gets user's region from profile if not provided
- ✅ Fixed product quantity validation: `quantity` → `quantity_available`
- ✅ Fixed product quantity updates: `quantity` → `quantity_available`

**Impact:** Mobile app can now create orders successfully

### 2. Auth Controller - Registration Delay
**File:** `backend/src/controllers/authController.js`

**Problem:** 500ms delay too short for Supabase trigger execution

**Changes:**
- ✅ Increased delay: 500ms → 2000ms
- ✅ Added explanatory comment about Supabase trigger timing

**Impact:** Registration will succeed immediately instead of returning 500 error

---

## 📋 Code Changes Summary

### Order Controller Changes
```javascript
// Line ~140: Accept both address formats
const { items, deliveryAddress, shippingAddress, paymentMethod, notes } = req.body;

// Lines 145-170: Normalize address format for mobile compatibility
if (shippingAddress) {
  normalizedAddress = shippingAddress;
  buyerRegion = shippingAddress.region;
} else if (deliveryAddress) {
  if (typeof deliveryAddress === 'string') {
    normalizedAddress = { address: deliveryAddress, region: buyer?.region || 'Central' };
  } else {
    normalizedAddress = deliveryAddress;
  }
  buyerRegion = normalizedAddress.region || buyer?.region || 'Central';
}

// Line ~190: Fixed quantity validation
if (product.quantity_available < item.quantity)

// Line ~270: Fixed quantity update
update({ quantity_available: product.quantity_available - item.quantity })
```

### Auth Controller Changes
```javascript
// Line 31: Increased trigger wait time
await new Promise(resolve => setTimeout(resolve, 2000)); // was 500
```

---

## 🚀 Deployment Instructions

### Step 1: Commit Changes
```bash
cd C:\Users\USER\AgriSupply

# Check what was changed
git status

# Add the modified files
git add backend/src/controllers/orderController.js
git add backend/src/controllers/authController.js

# Commit with descriptive message
git commit -m "Fix field name compatibility between mobile app and backend

- Accept both deliveryAddress (mobile) and shippingAddress (web) in order creation
- Fixed product quantity field names (quantity_available)
- Increased registration delay to 2000ms for Supabase trigger
- Backwards compatible with both mobile and web apps"

# Push to trigger Render auto-deployment
git push origin main
```

### Step 2: Monitor Deployment
1. Go to: https://dashboard.render.com
2. Find your service: `agrisupply-farm-connect-system`
3. Check "Events" tab for deployment progress
4. Wait ~2-3 minutes for build and deploy
5. Verify "Live" badge appears

### Step 3: Verify Fixes
**Test Registration:**
```powershell
$regData = '{"email":"test' + (Get-Random) + '@gmail.com","password":"SecurePass123!","fullName":"Test User","phone":"+256701234567","role":"farmer","region":"Central","district":"Kampala"}' | ConvertFrom-Json | ConvertTo-Json
Invoke-RestMethod -Uri "https://agrisupply-farm-connect-system.onrender.com/api/v1/auth/register" -Method POST -Body $regData -ContentType "application/json"
```
Should return 201 Created (not 500)

**Test Order Creation from Mobile App:**
- Open mobile app
- Add product to cart
- Create order with simple delivery address
- Should succeed without errors

---

## 🔑 Environment Variables to Add on Render

After deployment, add these from local .env:

### AI Assistant (Groq)
```
GROQ_API_KEY=<copy-from-backend/.env>
GROQ_MODEL=llama-3.1-70b-versatile
GROQ_VISION_MODEL=llama-3.2-90b-vision-preview
```

### Payment Provider (MarzPay)
```
MARZPAY_API_KEY=<copy-from-backend/.env>
MARZPAY_API_SECRET=<copy-from-backend/.env>
MARZPAY_API_URL=https://wallet.wearemarz.com/api/v1
MARZPAY_CALLBACK_URL=https://agrisupply-farm-connect-system.onrender.com/api/v1/payments/marzpay/callback
```

**How to Add:**
1. Render Dashboard → Your Service
2. Click "Environment" tab
3. Click "Add Environment Variable"
4. Paste each key=value pair
5. Click "Save Changes" (service will restart)

---

## ✅ What This Fixes

| Issue | Before | After |
|-------|--------|-------|
| **Order Creation** | ❌ 400 error - field mismatch | ✅ Works with mobile string address |
| **Product Quantity** | ❌ Wrong field name | ✅ Uses quantity_available |
| **Registration** | ⚠️ 500 error (works on retry) | ✅ Succeeds immediately |
| **Field Compatibility** | ❌ Mobile/backend mismatch | ✅ Backwards compatible |

---

## 📱 Mobile App Compatibility

**Mobile Field Names (Already Correct):**
```dart
// Product creation - COMPATIBLE ✅
'quantity': product.quantity.toString()
'isOrganic': product.isOrganic.toString()

// Order creation - NOW COMPATIBLE ✅
'deliveryAddress': deliveryAddress  // String or object both work
'items': items
'paymentMethod': paymentMethod
```

**No mobile app changes needed!** Backend now accepts mobile's format.

---

## 🎯 Testing Checklist

After deployment, verify:
- [ ] Registration completes without 500 error
- [ ] Login works immediately after registration
- [ ] Product creation from mobile app works
- [ ] Order creation from mobile app works  
- [ ] Cart → Checkout → Order flow completes
- [ ] AI assistant responds (after env vars added)
- [ ] Payment initiation works (after env vars added)

---

## 📝 Notes

- **Backwards Compatible:** Both old and new field names work
- **Database Schema:** No changes needed - already uses `quantity_available`
- **Mobile App:** No changes needed - backend adapted to mobile format
- **Web App:** Will continue to work with `shippingAddress` object format

**All changes are backwards compatible!** 🎉
