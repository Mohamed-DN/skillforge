# 🤖 AI Context — SkillForge

> **This file is for AI assistants** (Claude, Gemini, GPT, Copilot, etc.).
> It provides the context needed to understand, navigate, and contribute to this project.

---

## Project Identity

- **Name**: SkillForge
- **Type**: AI-powered career learning platform (SaaS, B2C)
- **Stage**: Early development (scaffolding complete, services not yet implemented)
- **Architecture**: Event-driven microservices on Kubernetes
- **Container Engine**: Podman (rootless, daemonless — chosen for bank-level security)
- **Primary Language**: Python 3.12+
- **Framework**: FastAPI (all services)
- **Key Book Reference**: *"Designing Data-Intensive Applications"* v2 (Kleppmann & Riccomini)
- **Security Level**: Bank-grade (mTLS, encryption at rest + transit, GDPR, audit logs)
- **GitHub**: https://github.com/Mohamed-DN/skillforge

---

## Architecture Overview

### Services (all in `/services/`)

| Service | Port | Role | Status |
|---------|------|------|--------|
| `api-gateway` | 8000 | Public REST API, request validation, event publishing | 🔴 Not started |
| `auth-service` | 8005 | OAuth2, JWT (RS256), bcrypt, RBAC, MFA, GDPR | 🔴 Not started |
| `billing-service` | 8006 | Stripe, subscriptions (Free/Pro/Enterprise), invoices | 🔴 Not started |
| `llm-gateway` | 8001 | LiteLLM model router (DeepSeek/Gemini/OpenAI) | 🔴 Not started |
| `ai-worker` | — | Redpanda consumer, AI processing, pgvector writes | 🔴 Not started |
| `assessment-engine` | 8002 | Adaptive quiz generation with RAG | 🔴 Not started |
| `user-profile-service` | 8003 | User domain, competency vectors | 🔴 Not started |
| `cv-analyzer` | — | CV parsing worker (PDF/DOCX → skills) | 🔴 Not started |
| `notification-service` | 8004 | Push/email/in-app notifications | 🔴 Not started |

### Infrastructure

| Component | Technology | Config Location |
|-----------|-----------|----------------|
| Container Engine | Podman (rootless) | `infra/containers/` |
| Event Bus | Redpanda (Kafka-compatible) | `infra/helm/redpanda-values.yaml` |
| Database | PostgreSQL + pgvector + TimescaleDB | `database/` |
| Cache/Sessions | Redis (or Valkey) | `infra/helm/redis-values.yaml` |
| Autoscaler | KEDA | `infra/helm/keda-values.yaml` |
| Object Storage | MinIO (S3-compatible) | `infra/terraform/` |
| Secrets | HashiCorp Vault | `infra/helm/vault-values.yaml` |
| Observability | OpenTelemetry + Prometheus + Grafana | `observability/` |
| Image Scanning | Trivy | `.github/workflows/ci.yml` |

### Communication Patterns

- **Sync**: REST (FastAPI) for user-facing API calls
- **Async**: Redpanda events for all background processing
- **Pattern**: Event Sourcing + CQRS + Transactional Outbox
- **Serialization**: Protobuf for inter-service events, JSON for REST API
- **Security**: mTLS between services, TLS 1.3 external, JWT for auth

---

## Key Design Decisions

1. **Podman over Docker** — Rootless by default, no daemon, K8s-native, 100% free, bank-level security
2. **Kappa Architecture** — No separate batch layer. All processing through Redpanda stream consumers
3. **LLM Gateway abstraction** — All AI calls go through LiteLLM. Never call LLM APIs directly
4. **Idempotent consumers** — Every event consumer must be idempotent (use event_id for deduplication)
5. **Transactional outbox** — Events written to DB in same transaction as state changes
6. **RS256 JWT** — Asymmetric signing: private key signs, public key verifies (zero-trust between services)
7. **Stripe for payments** — PCI-compliant, never touch card data directly
8. **GDPR by design** — Consent records, right to erasure, data portability built-in
9. **Competency vectors** — User skills as pgvector embeddings (1536-dim), updated incrementally
10. **Schema evolution** — All event schemas use Protobuf with backward/forward compatibility

---

## Conventions

### Code Style
- **Python**: Black formatter (line 100), isort imports, mypy strict, ruff linter
- **Naming**: snake_case (Python), kebab-case (service dirs), SCREAMING_SNAKE (env vars)
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `infra:`)

### Branch Strategy
- `main` — stable, deployable
- `develop` — integration branch
- `feat/<name>`, `fix/<name>` — feature/fix branches

### Service Structure
```
services/<name>/
├── src/
│   ├── __init__.py
│   ├── main.py          # FastAPI app or worker entrypoint
│   ├── config.py         # Pydantic Settings
│   ├── models.py         # SQLAlchemy/Pydantic models
│   ├── routes.py         # API routes (if HTTP service)
│   ├── events.py         # Event producers/consumers
│   └── services.py       # Business logic
├── tests/
├── Containerfile         # OCI-compatible (works with Podman)
├── requirements.txt
└── README.md
```

---

## Current Progress

> **Last updated**: 2026-03-22

- ✅ Repository scaffolding complete (9 services)
- ✅ Architecture documentation (README, AI_CONTEXT, ROADMAP, PERSONAL_GUIDE)
- ✅ Database schema with pgvector + TimescaleDB + outbox + auth + billing tables
- ✅ Protobuf event schemas
- ✅ Podman-compose for local dev
- 🔴 No service code implemented yet
- 🔴 No K8s manifests created yet
- 🔴 No CI/CD pipelines active yet

**Next milestone**: Phase 1 — Database schema + Auth Service skeleton

---

## How to Update This File

When implementing new features:
1. Update the service status table above
2. Update "Current Progress"
3. Add any new design decisions
4. If adding a new service, add it to the services table
