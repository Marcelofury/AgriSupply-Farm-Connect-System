# Relworx API Testing - Quick Reference

## Test Scenarios

### Scenario 1: Complete Payment Flow (MTN)

```bash
# Step 1: Validate phone (optional)
curl -X POST http://localhost:3000/api/v1/payments/validate-phone \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"phone": "+256771234567"}'

# Step 2: Initiate payment
curl -X POST http://localhost:3000/api/v1/payments/initiate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORDER_UUID_HERE",
    "method": "relworx_mobile",
    "phone": "+256771234567"
  }'

# Step 3: Check status (use transactionRef from step 2)
curl http://localhost:3000/api/v1/payments/verify/TXN-12345678 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### Scenario 2: Complete Payment Flow (Airtel)

```bash
# Step 1: Initiate payment
curl -X POST http://localhost:3000/api/v1/payments/initiate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORDER_UUID_HERE",
    "method": "relworx_mobile",
    "phone": "+256701234567"
  }'

# Step 2: User approves on phone
# (Check mobile device for payment prompt)

# Step 3: Verify payment
curl http://localhost:3000/api/v1/payments/verify/TXN-RETURNED-FROM-STEP-1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### Scenario 3: Admin - Check Wallet Balance

```bash
curl http://localhost:3000/api/v1/payments/wallet-balance?currency=UGX \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

### Scenario 4: Admin - Get Transaction History

```bash
curl http://localhost:3000/api/v1/payments/relworx-transactions \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

### Scenario 5: Get Available Payment Methods

```bash
curl http://localhost:3000/api/v1/payments/methods
```

---

## Phone Number Formats

### Valid Formats:
- `+256771234567` ✅
- `+256701234567` ✅
- `0771234567` ✅ (auto-converted to +256...)
- `0701234567` ✅ (auto-converted to +256...)

### Invalid Formats:
- `771234567` ❌ (missing prefix)
- `256771234567` ❌ (missing +)
- `+256 77 123 4567` ❌ (spaces)

---

## Expected Response Codes

| Code | Meaning | Next Action |
|------|---------|-------------|
| 200 | Success | Proceed to next step |
| 400 | Bad request | Check phone format, amount, reference |
| 401 | Unauthorized | Verify auth token |
| 404 | Not found | Check order ID or transaction reference |
| 429 | Rate limited | Wait 10 minutes |
| 500 | Server error | Check logs, retry later |

---

## Payment Status Flow

```
pending → processing → completed
                    └→ failed
```

**Status Values:**
- `pending` - Payment initiated, waiting for user approval
- `processing` - User approved, transaction in progress
- `completed` - Payment successful ✅
- `failed` - Payment failed ❌

---

## Testing Checklist

- [ ] Test MTN payment (+25677...)
- [ ] Test Airtel payment (+25670...)
- [ ] Test phone validation
- [ ] Test payment status checking
- [ ] Test with invalid phone number (error handling)
- [ ] Test with invalid amount (error handling)
- [ ] Test rate limiting (5 requests in 10 mins)
- [ ] Test wallet balance check (admin)
- [ ] Test transaction history (admin)
- [ ] Test payment method listing

---

## Common Test Phone Numbers

**MTN Uganda Prefixes:**
- 077... (most common)
- 078...
- 076...

**Airtel Uganda Prefixes:**
- 070... (most common)
- 075...
- 074...

⚠️ **Note:** Use real phone numbers you control for testing. Relworx doesn't provide test numbers in sandbox mode.

---

## Debugging Tips

1. **Check backend logs:**
   ```bash
   # View logs in real-time
   tail -f backend/logs/app.log
   ```

2. **Check Supabase payments table:**
   - Open Supabase dashboard
   - Navigate to `payments` table
   - Filter by recent entries

3. **Check Relworx dashboard:**
   - Login to [https://payments.relworx.com](https://payments.relworx.com)
   - View transaction history
   - Check wallet balance

4. **Enable verbose logging:**
   ```env
   # In .env
   LOG_LEVEL=debug
   ```

---

## Rate Limiting Test

**Test rate limit enforcement:**

```bash
# Run this script to test rate limiting (5 requests max per 10 mins)
for i in {1..6}; do
  echo "Request $i"
  curl -X POST http://localhost:3000/api/v1/payments/initiate \
    -H "Authorization: Bearer YOUR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "orderId": "ORDER_UUID",
      "method": "relworx_mobile",
      "phone": "+256771234567"
    }'
  sleep 2
done

# Request 6 should return 429 (Too Many Requests)
```

---

## Mock Webhook Test

**Simulate Relworx callback:**

```bash
curl -X POST http://localhost:3000/api/v1/payments/relworx/callback \
  -H "Content-Type: application/json" \
  -d '{
    "customer_reference": "TXN-12345678",
    "internal_reference": "d3ae5e14f05fcc58427331d38cb11d42",
    "status": "success",
    "amount": 50000.0,
    "currency": "UGX",
    "provider": "MTN_UGANDA",
    "msisdn": "+256771234567",
    "provider_transaction_id": "1080783XXXXX",
    "completed_at": "2025-04-10T15:12:58.977+03:00"
  }'
```

---

## Environment-Specific Testing

### Local Development
```bash
# Use localhost
BASE_URL=http://localhost:3000/api/v1
```

### Staging
```bash
# Use staging server
BASE_URL=https://staging.agrisupply.com/api/v1
```

### Production
```bash
# Use production server
BASE_URL=https://api.agrisupply.com/api/v1
```

---

## Error Scenarios to Test

1. **Invalid phone number:**
   ```json
   {"phone": "invalid"}
   ```
   Expected: 400 Bad Request

2. **Non-existent order:**
   ```json
   {"orderId": "non-existent-uuid", "method": "relworx_mobile", "phone": "+256771234567"}
   ```
   Expected: 404 Not Found

3. **Already paid order:**
   ```json
   {"orderId": "paid-order-uuid", "method": "relworx_mobile", "phone": "+256771234567"}
   ```
   Expected: 400 "Order already paid"

4. **Zero amount:**
   Test with order that has 0 total
   Expected: 400 "Invalid amount"

5. **Expired auth token:**
   Use expired JWT token
   Expected: 401 Unauthorized

---

## Performance Benchmarks

**Expected response times:**
- Phone validation: < 2 seconds
- Payment initiation: < 3 seconds
- Status check: < 1 second
- Wallet balance: < 2 seconds

**Monitor for:**
- Response times > 5 seconds
- Error rate > 1%
- Webhook delivery delays > 30 seconds

---

## Quick Start Script

Save as `test-relworx.sh`:

```bash
#!/bin/bash

# Configuration
BASE_URL="http://localhost:3000/api/v1"
TOKEN="YOUR_AUTH_TOKEN"
ORDER_ID="YOUR_ORDER_UUID"
PHONE="+256771234567"

echo "1. Validating phone..."
curl -s -X POST $BASE_URL/payments/validate-phone \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"phone\": \"$PHONE\"}" | jq

echo -e "\n2. Initiating payment..."
RESPONSE=$(curl -s -X POST $BASE_URL/payments/initiate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"orderId\": \"$ORDER_ID\", \"method\": \"relworx_mobile\", \"phone\": \"$PHONE\"}")

echo $RESPONSE | jq
TXN_REF=$(echo $RESPONSE | jq -r '.data.transactionRef')

echo -e "\n3. Approve payment on your phone, then press Enter..."
read

echo "4. Checking payment status..."
curl -s $BASE_URL/payments/verify/$TXN_REF \
  -H "Authorization: Bearer $TOKEN" | jq

echo -e "\nDone!"
```

Run with:
```bash
chmod +x test-relworx.sh
./test-relworx.sh
```

---

**Happy Testing! 🚀**
