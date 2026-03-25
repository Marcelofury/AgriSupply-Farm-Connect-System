# MarzPay Integration Brief for GitHub Copilot

Use this document as the exact implementation request in another codebase.

## 1) Copy-Paste Prompt for Copilot

```text
Implement MarzPay mobile money payments (MTN + Airtel Uganda) in this project.

Tech assumptions:
- Backend is Node.js + Express
- Use axios for HTTP calls
- Use Basic Auth with API key/secret
- Follow production-grade error handling and logging

Requirements:
1. Create a MarzPay service module with these capabilities:
   - collectMoney({ reference, phoneNumber, country='UG', amount, description, callbackUrl? })
   - sendMoney({ reference, phoneNumber, country='UG', amount, description, callbackUrl? })
   - getCollectionDetails(uuid)
   - getSendMoneyDetails(uuid)
   - checkTransactionStatus(uuid)
   - getWalletBalance()
   - getTransactionHistory(params?)
   - getCollectionServices()
   - getSendMoneyServices()
   - formatPhoneNumber(phone) // supports 0..., 256..., +256...
   - getProvider(phone) // MTN: 77/78/76, Airtel: 70/75/74
   - validateMobileNumber(phone) // local validation that returns {valid, provider, message}

2. MarzPay API config:
   - Base URL: https://wallet.wearemarz.com/api/v1
   - Headers:
     - Content-Type: application/json
     - Accept: application/json
     - Authorization: Basic base64(API_KEY:API_SECRET)
   - Timeout: 30s

3. Create payment controller flow:
   - POST /payments/initiate accepts { orderId, method, phone }
   - support method: marzpay
   - for marzpay:
     - format and validate phone
     - provider check (MTN/Airtel only)
     - call collectMoney with payload fields:
       - reference
       - phoneNumber
       - country: 'UG'
       - amount
       - description
   - persist payment with transaction_ref/provider_reference
   - update order payment status to processing/pending

4. Add routes:
   - POST /payments/initiate
   - POST /payments/marzpay/callback
   - POST /payments/validate-phone
   - GET /payments/wallet-balance (admin)
   - GET /payments/marzpay-transactions (admin)

5. Add webhook handler:
   - Process callback payload
   - map statuses:
     - successful/completed -> completed
     - failed/cancelled -> failed
     - pending/processing -> pending
   - update payment + order atomically
   - log provider reference and status transitions

6. Validation rules:
   - amount must be between 500 and 10,000,000 UGX
   - phone must normalize to +256XXXXXXXXX (13 chars)
   - method must include marzpay

7. Environment variables:
   - MARZPAY_API_KEY
   - MARZPAY_API_SECRET
   - MARZPAY_API_URL (default to wallet.wearemarz.com/api/v1)
   - APP_BASE_URL for callback URL composition

8. Return contracts:
   - initiation response should include:
     - transactionRef
     - status
     - providerRef
     - message

9. Add tests:
   - phone formatting and provider detection
   - collectMoney request payload
   - callback status mapping
   - initiation endpoint success/failure paths

10. Add concise documentation in README:
   - setup
   - sample request/response
   - troubleshooting

Important implementation notes:
- Use phoneNumber and description fields when calling MarzPay collect API.
- Do not send non-supported fields like reason/currency to collect endpoint if API doesn’t require them.
- validateMobileNumber must exist if controller calls it.
- If wallet/balance check fails with IP whitelist error, document dashboard IP whitelisting steps.
- Make all failures return meaningful API errors (no raw stack traces).

Now implement all required files and wire them end-to-end.
```

## 2) Reference API Payloads

### Initiate Collection (MarzPay)

```json
{
  "amount": 500,
  "phone_number": "+256783858472",
  "country": "UG",
  "reference": "TXN-UNIQUE-REF",
  "description": "Order #123 payment"
}
```

### Expected Success Shape

```json
{
  "success": true,
  "message": "Collection initiated successfully.",
  "data": {
    "transactionRef": "TXN-UNIQUE-REF",
    "status": "pending",
    "providerRef": "provider-or-reference"
  }
}
```

## 3) Production Checklist

- Set env vars in deployment environment
- Whitelist backend server IP in MarzPay dashboard (required for some actions like balance)
- Configure webhook endpoint publicly: /payments/marzpay/callback
- Verify one MTN and one Airtel test number flow
- Confirm payment status transitions update order records
- Add retries and idempotency for webhook updates

## 4) Quick Smoke Test Script (Node)

```js
require('dotenv').config();
const marzpay = require('./src/services/marzpayService');

(async () => {
  const phone = '0783858472';
  const formatted = marzpay.formatPhoneNumber(phone);
  const provider = marzpay.getProvider(phone);
  const validation = await marzpay.validateMobileNumber(phone);

  console.log({ formatted, provider, validation });

  const result = await marzpay.collectMoney({
    phoneNumber: formatted,
    amount: 500,
    country: 'UG',
    description: 'Smoke test',
  });

  console.log(result);
})();
```

## 5) Known Pitfalls to Avoid

- Missing validateMobileNumber in service while controller calls it
- Sending local phone format directly to API without normalization
- Not handling UNKNOWN provider prefixes
- Not persisting provider reference/transaction reference
- No webhook reconciliation path for asynchronous completion
- Skipping IP whitelist setup in MarzPay dashboard

---

This brief is designed for direct use with GitHub Copilot to implement MarzPay end-to-end in a new system.
