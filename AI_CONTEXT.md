# 🤖 AI Context — Megaproject

> **This file is for AI assistants** (Claude, Gemini, GPT, Copilot, etc.).
> It provides the context needed to understand, navigate, and contribute to this project.

---

## Project Identity

- **Name**: Megaproject
- **Type**: AI-powered career learning platform
- **Stage**: Early development (scaffolding complete, services not yet implemented)
- **Architecture**: Event-driven microservices on Kubernetes
- **Primary Language**: Python 3.12+
- **Framework**: FastAPI (all services)
- **Key Book Reference**: *"Designing Data-Intensive Applications"* v2 (Kleppmann & Riccomini)

---

## Architecture Overview

### Services (all in `/services/`)

| Service | Port | Role | Status |
|---------|------|------|--------|
| `api-gateway` | 8000 | Public REST API, JWT auth, publishes events | 🔴 Not started |
| `llm-gateway` | 8001 | LiteLLM model router (DeepSeek/Gemini/OpenAI) | 🔴 Not started |
| `ai-worker` | — | Redpanda consumer, AI processing, pgvector writes | 🔴 Not started |
| `assessment-engine` | 8002 | Adaptive quiz generation with RAG | 🔴 Not started |
| `user-profile-service` | 8003 | User domain, competency vectors | 🔴 Not started |
| `cv-analyzer` | — | CV parsing worker (PDF/DOCX → skills) | 🔴 Not started |
| `notification-service` | 8004 | Push/email/in-app notifications | 🔴 Not started |

### Infrastructure

| Component | Technology | Config Location |
|-----------|-----------|----------------|
| Event Bus | Redpanda (Kafka-compatible) | `infra/helm/redpanda-values.yaml` |
| Database | PostgreSQL + pgvector + TimescaleDB | `database/` |
| Autoscaler | KEDA | `infra/helm/keda-values.yaml` |
| Object Storage | S3/MinIO | `infra/terraform/` |
| Observability | OpenTelemetry + Prometheus + Grafana | `observability/` |

### Communication Patterns

- **Sync**: REST (FastAPI) for user-facing API calls
- **Async**: Redpanda events for all background processing
- **Pattern**: Event Sourcing + CQRS + Transactional Outbox
- **Serialization**: Protobuf for inter-service events, JSON for REST API

---

## Key Design Decisions

1. **Kappa Architecture** — No separate batch layer. All processing through Redpanda stream consumers.
2. **LLM Gateway abstraction** — All AI calls go through LiteLLM. Never call LLM APIs directly from services.
3. **Idempotent consumers** — Every event consumer must be idempotent (use event_id for deduplication).
4. **Transactional outbox** — Events are written to `events_outbox` table in the same DB transaction as state changes, then published by a separate relay.
5. **Competency vectors** — User skills stored as pgvector embeddings (1536-dim), updated incrementally.
6. **Schema evolution** — All event schemas use Protobuf with backward/forward compatibility rules.

---

## Conventions

### Code Style
- **Python**: Black formatter, isort imports, mypy strict, ruff linter
- **Naming**: snake_case for Python, kebab-case for service dirs, SCREAMING_SNAKE for env vars
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `infra:`)

### Branch Strategy
- `main` — stable, deployable
- `develop` — integration branch
- `feat/<name>` — feature branches
- `fix/<name>` — bug fixes

### Service Structure (each service follows this)
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
│   ├── __init__.py
│   └── test_*.py
├── Dockerfile
├── requirements.txt
└── README.md
```

---

## Current Progress

> **Last updated**: 2026-03-22

- ✅ Repository scaffolding complete
- ✅ Architecture documentation (README.md, this file, ROADMAP.md)
- 🔴 No service code implemented yet
- 🔴 No database migrations created yet
- 🔴 No Kubernetes manifests created yet
- 🔴 No CI/CD pipelines active yet

**Next milestone**: Implement Phase 1 (see ROADMAP.md) — Database schema + API Gateway skeleton

---

## How to Update This File

When implementing new features or making architectural changes:
1. Update the service status table above
2. Update "Current Progress" section
3. Add any new design decisions to the "Key Design Decisions" section
4. If adding a new service, add it to the services table
