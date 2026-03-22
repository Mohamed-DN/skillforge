# 🗺️ Roadmap — Megaproject

> Your step-by-step guide from zero to production. Each phase builds on the previous one.
> Check off items as you complete them. This is your personal learning journal.

---

## Phase 0: Foundation ✅
> *Repository scaffolding and documentation*

- [x] Initialize Git repository
- [x] Create directory structure for all services
- [x] Write main README.md with architecture diagrams
- [x] Write AI_CONTEXT.md for AI assistants
- [x] Write this ROADMAP.md
- [x] Write CONTRIBUTING.md
- [x] Create .gitignore
- [x] Push initial commit to GitHub

---

## Phase 1: Database & Data Model 🔴
> *DDIA v2 Focus: Data Models, Storage Engines, Data Encoding*

- [ ] Install PostgreSQL locally (or use Docker)
- [ ] Enable extensions: `pgvector`, `timescaledb`
- [ ] Design and create the core schema:
  - [ ] `users` table (auth, profile, preferences)
  - [ ] `competency_vectors` table (pgvector embeddings)
  - [ ] `assessments` table (quiz definitions, questions)
  - [ ] `assessment_results` table (user answers, scores)
  - [ ] `learning_materials` table (content chunks + pgvector embeddings)
  - [ ] `learning_paths` table (personalized paths per user)
  - [ ] `user_progress` hypertable (TimescaleDB time-series)
  - [ ] `events_outbox` table (transactional outbox pattern)
- [ ] Set up Alembic for migration management
- [ ] Create initial migration
- [ ] Write seed data scripts
- [ ] Document schema in `database/schema.sql`

### 📚 What You'll Learn
- Relational data modeling, normalization vs denormalization tradeoffs
- Vector embeddings and similarity search (pgvector)
- Time-series data patterns (TimescaleDB hypertables)
- The transactional outbox pattern (exactly-once event publishing)

---

## Phase 2: API Gateway (First Microservice) 🔴
> *DDIA v2 Focus: Non-functional Requirements, API Design*

- [ ] Set up FastAPI project in `services/api-gateway/`
- [ ] Implement health check endpoint (`/health`, `/ready`)
- [ ] Implement JWT authentication (login/register)
- [ ] Create user CRUD endpoints
- [ ] Create assessment endpoints (start quiz, submit answer)
- [ ] Add request validation (Pydantic models)
- [ ] Add OpenAPI documentation
- [ ] Write unit tests
- [ ] Create Dockerfile
- [ ] Define SLOs (p99 latency < 100ms, availability > 99.9%)

### 📚 What You'll Learn
- FastAPI async patterns, dependency injection
- JWT authentication flow
- API versioning and backward compatibility
- Writing production-ready health checks

---

## Phase 3: Event Bus (Redpanda) 🔴
> *DDIA v2 Focus: Stream Processing, Message Delivery Semantics*

- [ ] Deploy Redpanda locally (Docker Compose)
- [ ] Define event schemas in Protobuf:
  - [ ] `UserRegistered`
  - [ ] `UserAnsweredQuestion`
  - [ ] `CVUploaded`
  - [ ] `CompetencyVectorUpdated`
  - [ ] `LearningPathGenerated`
  - [ ] `AssessmentCompleted`
- [ ] Set up Schema Registry
- [ ] Configure topics (`topics.yaml`):
  - [ ] Partition strategy (by `user_id`)
  - [ ] Retention policies
  - [ ] Replication factor
- [ ] Create shared Python event client (`libs/py-common/`)
- [ ] Integrate API Gateway → publish events on user actions
- [ ] Implement the transactional outbox relay

### 📚 What You'll Learn
- Event-driven architecture fundamentals
- Schema evolution and compatibility (backward/forward)
- Partitioning strategies for ordered event processing
- Exactly-once delivery semantics

---

## Phase 4: LLM Gateway 🔴
> *DDIA v2 Focus: Trade-offs, Service Architecture*

- [ ] Deploy LiteLLM as a service in `services/llm-gateway/`
- [ ] Configure model routing:
  - [ ] DeepSeek for fast/cheap tasks (quiz generation)
  - [ ] Google Gemini for long-context tasks (CV analysis)
  - [ ] OpenAI GPT for general reasoning
- [ ] Add fallback logic (if primary model fails, try secondary)
- [ ] Add cost tracking and token usage logging
- [ ] Add rate limiting per model provider
- [ ] Create health checks for each provider
- [ ] Write integration tests with mock LLM responses
- [ ] Create Dockerfile

### 📚 What You'll Learn
- Multi-provider LLM abstraction
- Fallback and retry patterns
- Cost optimization for AI workloads
- LiteLLM configuration and customization

---

## Phase 5: AI Workers 🔴
> *DDIA v2 Focus: Stream Processing, Derived Data, Materialized Views*

- [ ] Create AI Worker service (`services/ai-worker/`)
- [ ] Implement Redpanda consumer (consume `UserAnsweredQuestion` events)
- [ ] Implement skill analysis logic:
  - [ ] Call LLM Gateway to analyze answer depth
  - [ ] Compute updated competency vector
  - [ ] Store updated vector in pgvector
- [ ] Implement dead-letter queue for failed processing
- [ ] Make consumers idempotent (event_id deduplication)
- [ ] Add circuit breaker for LLM Gateway calls
- [ ] Write unit + integration tests
- [ ] Create Dockerfile

### 📚 What You'll Learn
- Consumer group patterns
- Idempotent event processing
- Circuit breaker pattern
- Derived data from event streams

---

## Phase 6: Assessment Engine + RAG 🔴
> *DDIA v2 Focus: Derived Data, Search, Query Processing*

- [ ] Create Assessment Engine service (`services/assessment-engine/`)
- [ ] Implement adaptive quiz generation:
  - [ ] Fetch user's competency vector from pgvector
  - [ ] RAG query: vector similarity search on `learning_materials`
  - [ ] Generate questions via LLM Gateway
  - [ ] Implement "stealth questions" injection (15% from adjacent domains)
- [ ] Implement quiz evaluation logic
- [ ] Write comprehensive tests
- [ ] Create Dockerfile

### 📚 What You'll Learn
- Retrieval Augmented Generation (RAG) pipeline
- Vector similarity search (cosine, L2, inner product)
- Hybrid search (vector + keyword + temporal)
- Adaptive difficulty algorithms

---

## Phase 7: CV Analyzer 🔴
> *DDIA v2 Focus: Batch vs Stream, Data Pipelines*

- [ ] Create CV Analyzer service (`services/cv-analyzer/`)
- [ ] Implement PDF/DOCX parsing (PyPDF2, python-docx)
- [ ] Implement skill extraction via LLM Gateway
- [ ] Generate initial competency vector from CV
- [ ] Store CV in S3-compatible storage (MinIO)
- [ ] Publish `CVAnalyzed` event with extracted skills
- [ ] Write tests
- [ ] Create Dockerfile

### 📚 What You'll Learn
- Document parsing and text extraction
- Information extraction with LLMs
- Object storage patterns (S3 API)
- Processing pipeline design

---

## Phase 8: User Profile & Notification Services 🔴
> *DDIA v2 Focus: Microservice boundaries, Domain-Driven Design*

- [ ] Create User Profile service (`services/user-profile-service/`)
  - [ ] CRUD for user profiles
  - [ ] Career goals management
  - [ ] Competency vector retrieval API
  - [ ] Learning history aggregation
- [ ] Create Notification service (`services/notification-service/`)
  - [ ] Email notifications (learning milestones)
  - [ ] In-app notifications
  - [ ] Consume relevant events from Redpanda
- [ ] Write tests for both services
- [ ] Create Dockerfiles

### 📚 What You'll Learn
- Service boundary design (DDD bounded contexts)
- Event-driven notification patterns
- Email delivery with retry logic

---

## Phase 9: Kubernetes Deployment 🔴
> *DDIA v2 Focus: Deployment, Scaling, Fault Tolerance*

- [ ] Write Kubernetes manifests for all services:
  - [ ] Deployments with resource limits
  - [ ] Services (ClusterIP, NodePort as needed)
  - [ ] ConfigMaps for configuration
  - [ ] Secrets for API keys
- [ ] Set up Kustomize overlays (dev vs prod)
- [ ] Deploy Redpanda via Helm
- [ ] Deploy PostgreSQL via Helm (with pgvector + TimescaleDB)
- [ ] Install and configure KEDA:
  - [ ] ScaledObject for AI Worker (scale on consumer lag)
  - [ ] ScaledObject for CV Analyzer
- [ ] Set up Ingress (NGINX or Traefik)
- [ ] Test full deployment on Minikube/Kind
- [ ] Document deployment in runbooks

### 📚 What You'll Learn
- Kubernetes resource management
- Kustomize for environment-specific configs
- KEDA event-driven autoscaling
- Helm chart management
- Production readiness patterns

---

## Phase 10: Observability 🔴
> *DDIA v2 Focus: Monitoring, Debugging Distributed Systems*

- [ ] Deploy OpenTelemetry Collector
- [ ] Instrument all services with OpenTelemetry SDK:
  - [ ] Traces (request → event → worker → LLM → DB)
  - [ ] Metrics (request count, latency, error rate)
  - [ ] Structured JSON logs
- [ ] Deploy Prometheus + Grafana
- [ ] Create dashboards:
  - [ ] System overview (all services health)
  - [ ] AI Worker throughput and latency
  - [ ] Redpanda consumer lag
  - [ ] Database query performance
  - [ ] LLM cost tracking
- [ ] Create alerting rules:
  - [ ] High p99 latency
  - [ ] Queue depth spike
  - [ ] Error rate > threshold
  - [ ] LLM provider outage

### 📚 What You'll Learn
- Distributed tracing across microservices
- Prometheus query language (PromQL)
- Grafana dashboard design
- Alerting strategies for data-intensive systems

---

## Phase 11: CI/CD Pipeline 🔴
> *DDIA v2 Focus: Maintainability, Evolvability*

- [ ] Create GitHub Actions CI workflow:
  - [ ] Lint (ruff, mypy)
  - [ ] Unit tests (pytest)
  - [ ] Integration tests
  - [ ] Build Docker images
  - [ ] Push to container registry
- [ ] Create GitHub Actions CD workflow:
  - [ ] Deploy to staging on PR merge
  - [ ] Deploy to production on release tag
- [ ] Add branch protection rules
- [ ] Add automated schema compatibility checks

### 📚 What You'll Learn
- CI/CD pipeline design
- Container image lifecycle
- GitOps deployment patterns
- Automated quality gates

---

## Phase 12: Production Hardening 🔴
> *DDIA v2 Focus: Reliability, The Trouble with Distributed Systems*

- [ ] Implement rate limiting on API Gateway
- [ ] Add request tracing correlation IDs
- [ ] Implement graceful shutdown for all services
- [ ] Add Pod Disruption Budgets
- [ ] Implement database connection pooling
- [ ] Add retry logic with exponential backoff everywhere
- [ ] Security audit:
  - [ ] Input sanitization
  - [ ] SQL injection prevention (parameterized queries)
  - [ ] Secret rotation strategy
  - [ ] Network policies (pod-to-pod isolation)
- [ ] Load testing (k6 or locust)
- [ ] Chaos testing (kill pods, simulate network partition)

### 📚 What You'll Learn
- Production reliability engineering
- Chaos engineering principles
- Security hardening for microservices
- Load and stress testing

---

## Phase 13: Frontend (Optional) 🔴
> *Not DDIA-focused, but needed for a complete product*

- [ ] Choose framework (Next.js or React + Vite)
- [ ] Implement authentication UI
- [ ] Build dashboard (learning progress, competency radar chart)
- [ ] Build quiz interface
- [ ] Build CV upload interface
- [ ] Build learning path visualization
- [ ] Connect to API Gateway via REST/WebSocket

---

## 🏆 Graduation Criteria

When you've completed Phases 1-12, you will have built:

- ✅ A **production-grade, event-driven microservices system**
- ✅ An **AI-powered application** with intelligent model routing
- ✅ A **Kubernetes-native deployment** with auto-scaling
- ✅ A **data-intensive system** implementing core DDIA v2 patterns
- ✅ A **portfolio project** that demonstrates senior-level engineering

**This is not just a project — it's proof that you can design and build systems at scale.**
