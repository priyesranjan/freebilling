# India-Scale ERP Bill Stack

## What Is Implemented In This Flutter App

- Business Owner phone login via OTP flow (2factor-ready service abstraction).
- OTP request and OTP verify UI built into the Owner section gate.
- Mock OTP mode for local development when no 2factor API key is configured.
- Owner session state with logout support.

## 2factor Login Architecture (Recommended Production)

Do not expose 2factor API key in Flutter client for production.

1. Flutter app calls your backend:
- POST /v1/auth/owner/request-otp
- POST /v1/auth/owner/verify-otp

2. Backend calls 2factor APIs:
- Request OTP: /API/V1/{apiKey}/SMS/{phone}/AUTOGEN/{template}
- Verify OTP: /API/V1/{apiKey}/SMS/VERIFY/{requestId}/{otp}

3. Backend returns:
- short-lived access token (JWT)
- refresh token (httpOnly cookie or secure storage strategy)
- owner profile and tenant/business context

## Cloudflare R2 Storage Design

Use R2 for binary assets only:
- product images
- invoice PDFs
- business documents
- exports and backups

Pattern:
1. Flutter asks backend for pre-signed upload URL.
2. Flutter uploads file directly to R2.
3. Backend stores file metadata in Postgres.
4. Public invoice links serve via Cloudflare CDN + signed URL policy.

Suggested object keys:
- tenant/{tenantId}/products/{productId}/{filename}
- tenant/{tenantId}/invoices/{invoiceId}/{pdfFile}
- tenant/{tenantId}/exports/{year}/{month}/{file}

## India-Ready Production Stack

## Core App
- Flutter (Android + Web)
- Backend: Node.js (NestJS/Fastify) or Go (Fiber/Gin)
- API style: REST + OpenAPI

## Data
- PostgreSQL (primary relational store)
- Redis (OTP throttling, sessions, cache, idempotency keys)
- ClickHouse or BigQuery (analytics at scale, optional)

## Messaging & Notifications
- 2factor.in for OTP
- WhatsApp: Meta Cloud API or approved BSP
- SMS transactional: DLT-compliant provider
- Email: SES/SendGrid/Postmark
- Queue: RabbitMQ or Kafka for async notifications and retries

## Payments & Billing Plans
- Razorpay for Indian subscription collection
- Webhooks for payment success/failure and auto plan updates

## Infra & Security
- Cloudflare (WAF, CDN, Bot protection, rate limiting)
- Cloudflare R2 (object storage)
- Secret manager (AWS/GCP/1Password/Vault)
- TLS everywhere, audit logs, role-based access control

## Observability
- Structured logs (Loki/ELK)
- Metrics (Prometheus + Grafana)
- Error monitoring (Sentry)
- Uptime checks and synthetic monitoring

## Compliance for India
- DLT compliance for SMS routes/templates
- Privacy policy + consent records
- Data retention policy per invoice/legal needs
- Per-tenant logical isolation and strict access checks

## Backend API Minimum Set

Auth:
- POST /v1/auth/owner/request-otp
- POST /v1/auth/owner/verify-otp
- POST /v1/auth/refresh
- POST /v1/auth/logout

Owner Operations:
- GET /v1/owner/me
- POST /v1/products
- GET /v1/products
- POST /v1/invoices
- GET /v1/invoices/{invoiceId}

File Storage:
- POST /v1/files/presign-upload
- POST /v1/files/confirm

Admin:
- POST /v1/admin/businesses
- PATCH /v1/admin/businesses/{id}/status
- PATCH /v1/admin/businesses/{id}/plan

## Environment Variables

Flutter (dev only):
- TWO_FACTOR_API_KEY
- TWO_FACTOR_TEMPLATE

Backend:
- TWO_FACTOR_API_KEY
- TWO_FACTOR_TEMPLATE
- R2_ACCOUNT_ID
- R2_ACCESS_KEY_ID
- R2_SECRET_ACCESS_KEY
- R2_BUCKET
- R2_PUBLIC_BASE_URL
- JWT_ACCESS_SECRET
- JWT_REFRESH_SECRET

## Scale Targets (Initial)

- 10k businesses
- 1M invoices per month
- p95 API latency < 300ms for read APIs
- notification success rate > 98%
- 99.9% uptime target
