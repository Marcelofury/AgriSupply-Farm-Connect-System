# AgriSupply Security Policy

## Reporting Security Vulnerabilities

We take the security of AgriSupply seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

1. **Email**: security@agrisupply.ug
2. **Subject**: [SECURITY] Brief description of vulnerability
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

| Stage | Timeline |
|-------|----------|
| Initial Response | 24 hours |
| Vulnerability Assessment | 48 hours |
| Fix Development | 1-2 weeks |
| Public Disclosure | After fix deployed |

### Bug Bounty

We offer rewards for responsibly disclosed vulnerabilities:

| Severity | Reward (UGX) |
|----------|--------------|
| Critical | 2,000,000 - 5,000,000 |
| High | 500,000 - 2,000,000 |
| Medium | 100,000 - 500,000 |
| Low | 50,000 - 100,000 |

---

## Security Measures

### Authentication

#### Password Security
- Minimum 8 characters
- Requires uppercase, lowercase, and number
- Passwords hashed with bcrypt (12 rounds)
- No password stored in plain text

#### Token Security
- JWT tokens with short expiration (7 days)
- Refresh tokens with longer expiration (30 days)
- Tokens invalidated on logout
- Secure token storage (not in localStorage)

#### Multi-Factor Authentication
- SMS OTP for phone verification
- Required for sensitive operations
- Rate-limited OTP attempts

### Authorization

#### Role-Based Access Control (RBAC)

```
┌─────────────────────────────────────────────────────────┐
│                        Admin                            │
│  - Full system access                                   │
│  - User management                                      │
│  - System configuration                                 │
│  - View all data                                        │
├─────────────────────────────────────────────────────────┤
│                        Farmer                           │
│  - Manage own products                                  │
│  - View orders containing their products                │
│  - Update order status for their items                  │
│  - View own earnings and analytics                      │
├─────────────────────────────────────────────────────────┤
│                        Buyer                            │
│  - Browse products                                      │
│  - Create and view own orders                           │
│  - Manage own profile                                   │
│  - Write reviews for purchased products                 │
└─────────────────────────────────────────────────────────┘
```

#### Row Level Security (RLS)
- Database-level access control
- Users can only access own data
- Farmers can only modify own products
- Orders only visible to buyer and relevant farmers

### Data Protection

#### Encryption at Rest
- Database encrypted with AES-256
- Supabase managed encryption
- Encryption keys rotated regularly

#### Encryption in Transit
- TLS 1.2+ for all connections
- HTTPS enforced (HSTS enabled)
- Certificate pinning in mobile app

#### Sensitive Data Handling
- PII minimized and protected
- Payment data handled by providers
- No card numbers stored
- Phone numbers used for Mobile Money only

### API Security

#### Rate Limiting
```
General API:     100 requests/minute
Auth endpoints:  10 requests/minute
AI endpoints:    20 requests/hour
File uploads:    10 requests/minute
```

#### Input Validation
- Server-side validation for all inputs
- Input sanitization to prevent XSS
- SQL injection prevention via parameterized queries
- File type validation for uploads

#### Request Security
- CORS configured for allowed origins
- CSRF protection enabled
- Request size limits enforced
- Content-Type validation

### Infrastructure Security

#### Network Security
- API behind reverse proxy (Nginx)
- DDoS protection (Cloudflare)
- IP whitelisting for admin access
- VPC isolation for database

#### Container Security
- Minimal base images (Alpine)
- Non-root container users
- Read-only file systems where possible
- Regular image scanning

#### Secrets Management
- Environment variables for secrets
- No secrets in code or logs
- Secrets rotated regularly
- Access audited

### Monitoring & Logging

#### Security Logging
```
- Authentication attempts (success/failure)
- Authorization failures
- Password changes
- Profile updates
- Admin actions
- API errors
- Rate limit violations
```

#### Alerting
- Failed login threshold alerts
- Unusual activity patterns
- Rate limit breaches
- Error rate spikes
- Database access anomalies

### Compliance

#### Data Privacy
- GDPR-aligned practices
- Uganda Data Protection Act compliance
- Privacy policy published
- Data processing transparency

#### Payment Security
- PCI-DSS compliant payment providers
- No card storage on our servers
- Mobile Money via official APIs
- Transaction logs maintained

---

## Security Checklist for Development

### Code Review
- [ ] No hardcoded secrets
- [ ] Input validation on all endpoints
- [ ] Authentication required for protected routes
- [ ] Authorization checks for data access
- [ ] Error messages don't leak sensitive info
- [ ] Logging doesn't include sensitive data

### Deployment
- [ ] HTTPS enabled and enforced
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] CORS properly configured
- [ ] Secrets in environment variables
- [ ] Database connections encrypted

### Testing
- [ ] Authentication bypass tests
- [ ] Authorization bypass tests
- [ ] SQL injection tests
- [ ] XSS tests
- [ ] CSRF tests
- [ ] Rate limiting tests

---

## Incident Response

### Severity Levels

| Level | Description | Response Time |
|-------|-------------|---------------|
| P1 - Critical | Data breach, service down | 15 minutes |
| P2 - High | Security exploit, partial outage | 1 hour |
| P3 - Medium | Vulnerability discovered | 24 hours |
| P4 - Low | Security improvement needed | 1 week |

### Response Procedure

1. **Detection**
   - Alert received or report submitted
   - Initial assessment of severity

2. **Containment**
   - Isolate affected systems
   - Preserve evidence
   - Block malicious actors

3. **Investigation**
   - Root cause analysis
   - Impact assessment
   - Timeline reconstruction

4. **Remediation**
   - Apply fixes
   - Deploy patches
   - Verify resolution

5. **Recovery**
   - Restore normal operations
   - Monitor for recurrence
   - Update detection rules

6. **Post-Incident**
   - Document incident
   - Update procedures
   - Notify affected users (if required)
   - Report to authorities (if required)

---

## Security Contact

- **Email**: security@agrisupply.ug
- **PGP Key**: Available on request
- **Response**: Within 24 hours

---

Last Updated: January 2024
Version: 1.0
