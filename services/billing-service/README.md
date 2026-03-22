# Billing Service

Subscription management and payment processing for SkillForge.

## Subscription Tiers

| Tier | Monthly | Annual | Features |
|------|---------|--------|----------|
| **Free** | €0 | €0 | 5 quizzes/day, basic path |
| **Pro** | €9.99 | €99/year (save 17%) | Unlimited quizzes, CV analysis, analytics |
| **Enterprise** | €29.99 | €299/year (save 17%) | Pro + teams, priority AI, custom paths |

## Features
- **Stripe integration** — PCI-compliant payment processing
- **Webhook handling** — Stripe event verification (signature validation)
- **Subscription lifecycle** — Create, upgrade, downgrade, cancel, reactivate
- **Trial period** — 14-day free trial for Pro/Enterprise
- **Invoice generation** — Automatic invoice creation and storage
- **Usage metering** — Track AI queries, quizzes taken (for future usage-based pricing)
- **Proration** — Automatic proration on mid-cycle upgrades/downgrades
- **Dunning** — Handle failed payments, retry logic, grace period

## Events Produced
- `SubscriptionCreated` — New subscription
- `SubscriptionUpgraded` — Tier change (up)
- `SubscriptionDowngraded` — Tier change (down)
- `SubscriptionCancelled` — Cancellation (end of period)
- `PaymentSucceeded` — Successful charge
- `PaymentFailed` — Failed charge (triggers dunning)
- `InvoiceGenerated` — New invoice

## API Endpoints
- `GET /billing/plans` — List available plans
- `POST /billing/subscribe` — Create subscription (redirects to Stripe Checkout)
- `GET /billing/subscription` — Get current subscription
- `POST /billing/subscription/cancel` — Cancel (end of period)
- `POST /billing/subscription/upgrade` — Upgrade plan
- `GET /billing/invoices` — List invoices
- `GET /billing/invoices/:id` — Download invoice
- `POST /billing/webhooks/stripe` — Stripe webhook endpoint

## Tech
- FastAPI + Uvicorn
- stripe (Python SDK)
- SQLAlchemy (subscriptions, invoices)
- Pydantic v2 (validation)

## Running
```bash
cd services/billing-service
pip install -r requirements.txt
uvicorn src.main:app --reload --port 8006
```
