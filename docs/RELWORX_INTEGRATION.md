# Relworx Payment Gateway Integration Guide

## Overview

Relworx is now integrated as the **primary payment gateway** for AgriSupply, providing unified mobile money payments for both MTN and Airtel Uganda. This simplifies payment processing by consolidating multiple provider APIs into one.

---

## ✅ Feasibility Assessment

### **Status: HIGHLY FEASIBLE & RECOMMENDED**

#### Advantages over Previous Setup:

1. **Unified API** - Single integration for MTN & Airtel (vs separate integrations)
2. **Built-in Features:**
   - Phone number validation before payment
   - Real-time transaction status checking
   - Wallet balance monitoring
   - Last 30 days transaction history
   - Rate limiting protection (5 requests/10 mins per number)
3. **Simplified Credentials** - Single API key (vs multiple keys for MTN/Airtel)
4. **Multi-Currency Support** - UGX, KES, TZS
5. **Bidirectional Payments** - Both collections and disbursements

---

## Configuration

### Environment Variables

Already configured in `backend/.env`:

```dotenv
# Relworx Payment Gateway
RELWORX_API_KEY=2d7c867a440105.vJe8nd9228PdlXi5y6wvyA
RELWORX_ACCOUNT_NO=RELJH012BV45P
RELWORX_API_URL=https://payments.relworx.com/api
RELWORX_CALLBACK_URL=http://localhost:3000/api/payments/relworx/callback
```

⚠️ **For Production:** Update `RELWORX_CALLBACK_URL` to your production domain.

---

## API Endpoints

### 1. Initiate Payment

**Request:**
```bash
POST /api/v1/payments/initiate
Authorization: Bearer <user-token>
Content-Type: application/json

{
  "orderId": "uuid-of-order",
  "method": "relworx_mobile",
  "phone": "+256771234567"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment request sent. Please approve on your phone.",
  "data": {
    "transactionRef": "TXN-12345678",
    "status": "pending",
    "providerRef": "d3ae5e14f05fcc58427331d38cb11d42"
  }
}
```

---

### 2. Validate Phone Number

**Request:**
```bash
POST /api/v1/payments/validate-phone
Authorization: Bearer <user-token>
Content-Type: application/json

{
  "phone": "+256771234567"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "phone": "+256771234567",
    "provider": "MTN_UGANDA",
    "valid": true,
    "customerName": "JOHN DOE",
    "message": "Msisdn +256771234567 successfully validated."
  }
}
```

---

### 3. Check Payment Status

**Request:**
```bash
GET /api/v1/payments/verify/TXN-12345678
Authorization: Bearer <user-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "completed",
    "amount": 50000,
    "currency": "UGX",
    "provider": "MTN_UGANDA",
    "provider_transaction_id": "1080783XXXXX",
    "completed_at": "2025-04-10T15:12:58.977+03:00"
  }
}
```

---

### 4. Get Available Payment Methods

**Request:**
```bash
GET /api/v1/payments/methods
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "relworx_mobile",
      "name": "Mobile Money",
      "icon": "mobile_money",
      "description": "Pay with MTN or Airtel Mobile Money",
      "phonePrefixes": ["77", "78", "76", "70", "75", "74"],
      "supported": ["MTN Uganda", "Airtel Uganda"],
      "recommended": true
    },
    {
      "id": "card",
      "name": "Card Payment",
      "icon": "card",
      "description": "Pay with Visa or Mastercard"
    },
    {
      "id": "cash_on_delivery",
      "name": "Cash on Delivery",
      "icon": "cash",
      "description": "Pay when you receive your order"
    }
  ]
}
```

---

### 5. Admin: Check Wallet Balance

**Request:**
```bash
GET /api/v1/payments/wallet-balance?currency=UGX
Authorization: Bearer <admin-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "balance": 250000.0,
    "currency": "UGX"
  }
}
```

---

### 6. Admin: Get Transaction History

**Request:**
```bash
GET /api/v1/payments/relworx-transactions
Authorization: Bearer <admin-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "transactions": [
      {
        "customer_reference": "TXN-12345678",
        "provider": "MTN_UGANDA",
        "msisdn": "+256771234567",
        "transaction_type": "collection",
        "currency": "UGX",
        "amount": 50000.0,
        "status": "success",
        "created_at": "2025-06-24T12:50:14+03:00"
      }
    ]
  }
}
```

---

## Testing Guide

### Test Phone Numbers (Sandbox)

Contact Relworx support for sandbox/test phone numbers. Typically:
- **MTN Test:** +256770000000  
- **Airtel Test:** +256700000000

### Test Flow:

1. **Create an order** through the app
2. **Validate phone number** (optional but recommended):
   ```bash
   curl -X POST https://your-api.com/api/v1/payments/validate-phone \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"phone": "+256771234567"}'
   ```

3. **Initiate payment**:
   ```bash
   curl -X POST https://your-api.com/api/v1/payments/initiate \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "orderId": "order-uuid",
       "method": "relworx_mobile",
       "phone": "+256771234567"
     }'
   ```

4. **Approve payment** on mobile phone (enter PIN)

5. **Check status**:
   ```bash
   curl https://your-api.com/api/v1/payments/verify/TXN-12345678 \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

6. Monitor the logs for callback webhooks

---

## Implementation Details

### Files Created:
- `backend/src/services/relworxService.js` - Relworx API client

### Files Modified:
- `backend/.env` - Added Relworx credentials
- `backend/src/controllers/paymentController.js` - Added Relworx payment functions
- `backend/src/routes/paymentRoutes.js` - Added Relworx routes

### Key Functions:

**relworxService.js:**
- `requestPayment()` - Request payment from customer (collection)
- `sendPayment()` - Send payment to customer (disbursement/payout)
- `checkRequestStatus()` - Check transaction status
- `validateMobileNumber()` - Validate phone before payment
- `checkWalletBalance()` - Check Relworx wallet balance
- `getTransactionHistory()` - Get last 30 days transactions
- `formatPhoneNumber()` - Format phone to +256... format
- `getProvider()` - Detect MTN or Airtel from phone number

---

## Rate Limiting

⚠️ **Important:** Relworx enforces rate limiting:
- **5 requests per 10 minutes** per phone number (msisdn)
- Additional requests return `429 Too Many Requests`

**Recommendation:** Implement client-side validation to prevent rapid retry attempts.

---

## Error Handling

### Common Errors:

| HTTP Code | Error | Solution |
|-----------|-------|----------|
| 400 | Invalid phone number | Use format: +256... |
| 400 | Invalid reference length | Reference must be 8-36 chars |
| 400 | Invalid amount | Amount must be > 0 |
| 429 | Rate limit exceeded | Wait 10 minutes or use different number |
| 401 | Invalid API key | Check RELWORX_API_KEY in .env |
| 500 | Server error | Check Relworx service status |

---

## Migration from Legacy Providers

If you were using separate MTN/Airtel integrations:

1. **Keep legacy endpoints** - They still work for existing transactions
2. **Set Relworx as default** - New payments use `relworx_mobile`
3. **Update mobile app** - Change payment method selection to use `relworx_mobile`
4. **Monitor for 1-2 weeks** - Ensure all works correctly
5. **Remove legacy code** - Once confident, remove MTN/Airtel specific code

### Mobile App Changes:

Update payment method selection to use `relworx_mobile` instead of separate `mtn_mobile` and `airtel_money` options:

```dart
// OLD
if (provider == PaymentProvider.mtnMobile) {
  return await _initiateMTNPayment(...);
}

// NEW
if (provider == PaymentProvider.relworxMobile) {
  return await _initiateRelworxPayment(...);
}
```

---

## Production Deployment Checklist

- [ ] Update `RELWORX_CALLBACK_URL` to production domain
- [ ] Verify `RELWORX_API_KEY` and `RELWORX_ACCOUNT_NO` are correct
- [ ] Test with real phone numbers in production
- [ ] Set up monitoring/alerts for failed payments
- [ ] Configure webhook endpoint for callbacks
- [ ] Enable HTTPS for callbacks (required by Relworx)
- [ ] Add Relworx IP whitelist if required
- [ ] Monitor wallet balance regularly
- [ ] Set up automated balance alerts

---

## Support & Documentation

### Relworx Resources:
- **API Documentation:** [https://payments.relworx.com/docs](https://payments.relworx.com/docs)
- **Support Email:** support@relworx.com
- **Account Dashboard:** [https://payments.relworx.com/dashboard](https://payments.relworx.com/dashboard)

### AgriSupply Implementation:
- Check logs at `backend/logs/` for payment debugging
- Monitor Supabase `payments` table for transaction records
- Use admin endpoints for wallet monitoring and transaction history

---

## Security Best Practices

1. **Never expose API keys** - Keep in `.env`, never commit to git
2. **Validate webhooks** - Verify callback source (implement HMAC if Relworx provides)
3. **Use HTTPS** - Required for production callbacks
4. **Rate limiting** - Respect Relworx limits (5 req/10 min per number)
5. **Transaction idempotency** - Generate unique references per transaction
6. **Monitor balances** - Set alerts for low wallet balance
7. **Audit logs** - Keep records of all payment transactions

---

## Webhook Setup (Production)

Configure in Relworx dashboard:
- **Callback URL:** `https://your-domain.com/api/payments/relworx/callback`
- **Method:** POST
- **Content-Type:** application/json

Expected webhook payload:
```json
{
  "customer_reference": "TXN-12345678",
  "internal_reference": "d3ae5e14f05fcc58427331d38cb11d42",
  "status": "success",
  "amount": 50000.0,
  "currency": "UGX",
  "provider": "MTN_UGANDA",
  "msisdn": "+256771234567"
}
```

---

## Next Steps

1. ✅ **Integration Complete** - Relworx is now fully integrated
2. 🧪 **Test thoroughly** - Use test phone numbers in sandbox
3. 📱 **Update mobile app** - Switch to `relworx_mobile` payment method
4. 🚀 **Deploy to production** - Update callback URL and test with real numbers
5. 📊 **Monitor performance** - Track success rates and response times
6. 🔄 **Iterate** - Add features like saved payment methods, recurring payments

---

## Troubleshooting

### Payment stuck in "pending"
- Check transaction status via `/api/v1/payments/verify/:transactionId`
- Verify customer approved payment on their phone
- Check Relworx dashboard for transaction details

### "Invalid API key" error
- Verify `RELWORX_API_KEY` in `.env`
- Check API key hasn't expired
- Ensure Bearer token format is correct

### Phone validation failing
- Not all numbers support validation (only MTN & Airtel Uganda)
- Validation failure doesn't block payment
- Check phone format: +256...

### Rate limit errors
- User retrying too quickly (5 req/10 min limit)
- Implement exponential backoff
- Show user-friendly message with countdown

---

**Integration Status:** ✅ Complete & Ready for Testing
**Recommended Action:** Test in sandbox, then deploy to production
**Priority:** High - Simplifies payment processing significantly
