# 🗺️ Roadmap — SkillForge

> Your step-by-step guide from zero to production. Each phase builds on the previous one.
> Check off items as you complete them. This is your personal learning journal.
> **DDIA v2 chapter references** are noted for each phase.

---

## Phase 0: Foundation ✅
> *Repository scaffolding and documentation*

- [x] Initialize Git repository
- [x] Create directory structure for all 9 services
- [x] Write main README.md with architecture diagrams
- [x] Write AI_CONTEXT.md for AI assistants
- [x] Write PERSONAL_GUIDE.md (zero-to-hero manual)
- [x] Write this ROADMAP.md
- [x] Write CONTRIBUTING.md
- [x] Push to GitHub (github.com/Mohamed-DN/skillforge)

---

## Phase 1: Database & Data Model 🔴
> *DDIA v2: Ch3 (Data Models), Ch4 (Storage & Retrieval), Ch8 (Transactions)*

- [ ] Install PostgreSQL locally via Podman
- [ ] Enable extensions: `pgvector`, `timescaledb`
- [ ] Create core schema (users, credentials, competency_vectors, assessments, learning_materials, subscriptions, invoices, audit_log, gdpr_consent, events_outbox)
- [ ] Set up Alembic for migration management
- [ ] Create initial migration
- [ ] Write seed data scripts
- [ ] Test vector similarity search with sample embeddings

---

## Phase 2: Auth Service (Bank-Level) 🔴
> *DDIA v2: Ch8 (Transactions — ACID), Ch10 (Consistency & Consensus)*

- [ ] Set up FastAPI project in `services/auth-service/`
- [ ] Implement user registration (bcrypt, cost 12+)
- [ ] Implement JWT auth (RS256 asymmetric keys)
- [ ] Implement refresh token rotation (Redis)
- [ ] Implement RBAC (admin, learner, premium)
- [ ] Add rate-limited login (brute-force protection)
- [ ] Add password reset flow
- [ ] Implement GDPR endpoints (export, erase, consent)
- [ ] Write tests
- [ ] Create Containerfile

---

## Phase 3: API Gateway 🔴
> *DDIA v2: Ch2 (Non-functional Requirements)*

- [ ] Set up FastAPI in `services/api-gateway/`
- [ ] Health/readiness endpoints
- [ ] JWT validation middleware (calls auth-service)
- [ ] Request validation (Pydantic)
- [ ] User CRUD, assessment, CV upload endpoints
- [ ] OpenAPI docs
- [ ] Rate limiting (per-user, per-IP)
- [ ] Write tests + Containerfile
- [ ] Define SLOs (p99 < 100ms, availability > 99.9%)

---

## Phase 4: Event Bus (Redpanda) 🔴
> *DDIA v2: Ch5 (Encoding & Evolution), Ch12 (Stream Processing)*

- [ ] Deploy Redpanda via Podman Compose
- [ ] Define Protobuf event schemas (+ auth/billing events)
- [ ] Set up Schema Registry
- [ ] Configure topics (partitioning by user_id)
- [ ] Create shared event client (`libs/py-common/`)
- [ ] Integrate API Gateway → publish events
- [ ] Implement transactional outbox relay

---

## Phase 5: LLM Gateway 🔴
> *DDIA v2: Ch1 (Trade-offs)*

- [ ] Deploy LiteLLM in `services/llm-gateway/`
- [ ] Configure model routing (DeepSeek/Gemini/OpenAI)
- [ ] Add fallback logic + cost tracking
- [ ] Rate limiting per provider
- [ ] Write tests + Containerfile

---

## Phase 6: AI Workers 🔴
> *DDIA v2: Ch12 (Stream Processing), Ch13 (Philosophy of Streaming)*

- [ ] Create AI Worker with Redpanda consumer
- [ ] Implement skill analysis (LLM Gateway → pgvector update)
- [ ] Dead-letter queue + idempotent processing
- [ ] Circuit breaker for LLM calls
- [ ] Write tests + Containerfile

---

## Phase 7: Assessment Engine + RAG 🔴
> *DDIA v2: Ch4 (Storage & Retrieval — indexes, search)*

- [ ] RAG pipeline (pgvector similarity → LLM generation)
- [ ] Adaptive quiz with "stealth questions" (15% adjacent domain)
- [ ] Quiz evaluation
- [ ] Write tests + Containerfile

---

## Phase 8: CV Analyzer 🔴
> *DDIA v2: Ch12 (Stream Processing — data pipelines)*

- [ ] PDF/DOCX parsing
- [ ] Skill extraction via LLM
- [ ] Initial competency vector generation
- [ ] S3 storage (MinIO)
- [ ] Write tests + Containerfile

---

## Phase 9: Billing Service (Stripe) 🔴
> *DDIA v2: Ch8 (Transactions — ACID for payments)*

- [ ] Stripe integration (Checkout Sessions)
- [ ] Subscription lifecycle (create/upgrade/downgrade/cancel)
- [ ] Webhook handling (signature verification)
- [ ] Invoice generation
- [ ] Trial period management
- [ ] Payment event sourcing
- [ ] Write tests + Containerfile

---

## Phase 10: User Profile & Notifications 🔴
> *DDIA v2: Ch3 (Data Models — domain boundaries)*

- [ ] User Profile CRUD + competency vector API
- [ ] Notification service (email + in-app)
- [ ] Event-driven notifications from Redpanda
- [ ] Write tests + Containerfiles

---

## Phase 11: Kubernetes Deployment 🔴
> *DDIA v2: Ch6 (Replication), Ch7 (Sharding), Ch9 (Distributed Systems)*

- [ ] K8s manifests for all 12 services (Kustomize base/overlays)
- [ ] Configure Horizontal Pod Autoscaler (HPA) for compute nodes
- [ ] Deploy PostgreSQL 3-Node HA via CloudNativePG operator
- [ ] Deploy Redpanda 3-broker cluster via Helm (Raft consensus)
- [ ] Deploy Distributed MinIO with Erasure Coding
- [ ] KEDA ScaledObjects (AI Worker, CV Analyzer)
- [ ] Multi-replica Ingress (NGINX/Traefik + TLS 1.3) + LB
- [ ] Network policies (zero-trust)

---

## Phase 12: Security Hardening 🔴
> *DDIA v2: Ch9 (Trouble with Distributed Systems), Ch14 (Doing the Right Thing)*

- [ ] mTLS between services (cert-manager)
- [ ] HashiCorp Vault for secrets
- [ ] Trivy image scanning in CI
- [ ] Read-only root filesystem (Podman)
- [ ] Audit logging (immutable)
- [ ] GDPR full compliance review
- [ ] Load + chaos testing

---

## Phase 13: Observability 🔴
> *DDIA v2: Ch2 (Measuring Performance), Ch9 (Debugging)*

- [ ] OpenTelemetry instrumentation (all services)
- [ ] Prometheus + Grafana dashboards
- [ ] Alerting rules (latency, errors, queue depth, LLM cost)
- [ ] Distributed tracing end-to-end

---

## Phase 14: CI/CD 🔴
> *DDIA v2: Ch2 (Maintainability, Evolvability)*

- [ ] GitHub Actions CI (lint, test, build, Trivy scan)
- [ ] CD pipeline (deploy to staging/prod)
- [ ] Schema compatibility checks
- [ ] Branch protection rules

---

## Phase 15: Frontend (Optional) 🔴
- [ ] Next.js or React + Vite
- [ ] Auth UI, dashboard, quiz, CV upload, billing portal

---

## 🏆 Graduation

Phases 1-14 complete = **production-grade, bank-level secure, DDIA v2 showcase system**.
