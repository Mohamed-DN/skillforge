# SkillForge — System Improvement Plan

> This document tracks planned enhancements, optimizations, and future features.
> Items are prioritized by impact and grouped by category.

---

## 🔴 Priority 1: Security Hardening

### 1.1 Authentication Hardening
- [ ] Implement RS256 JWT key pair generation script (`scripts/generate-keys.sh`)
- [ ] Add JWT token blacklisting on logout (Redis SET with TTL)
- [ ] Implement refresh token rotation (new refresh token on each use)
- [ ] Add account lockout after 5 failed login attempts (15 min cooldown)
- [ ] Implement TOTP-based MFA (Google Authenticator compatible)
- [ ] Add email verification flow on registration
- [ ] Implement password strength validator (zxcvbn)

### 1.2 Encryption & Data Protection
- [ ] Enable TLS 1.3 on all service-to-service communication
- [ ] Implement mTLS with cert-manager (automatic certificate rotation)
- [ ] Encrypt sensitive database fields (MFA secrets, API keys) using pgcrypto
- [ ] Enable PostgreSQL SSL connections (`sslmode=verify-full`)
- [ ] Implement data-at-rest encryption for S3/MinIO buckets
- [ ] Add encryption for Redis data in transit

### 1.3 Network Security
- [ ] Write Kubernetes NetworkPolicies (deny-all default + service allow-lists)
- [ ] Implement API Gateway rate limiting (sliding window algorithm)
- [ ] Add IP-based rate limiting for login endpoints
- [ ] Configure CORS properly (no wildcard in production)
- [ ] Add security headers (HSTS, CSP, X-Frame-Options, X-Content-Type-Options)
- [ ] Implement request size limits to prevent DoS

### 1.4 Supply Chain Security
- [ ] Add Trivy container image scanning in CI (already in pipeline)
- [ ] Pin all dependency versions in requirements.txt
- [ ] Add Dependabot/Renovate for automated dependency updates
- [ ] Sign container images with cosign/sigstore
- [ ] Implement SBOM (Software Bill of Materials) generation

---

## 🟡 Priority 2: Reliability & Resilience

### 2.1 Fault Tolerance (DDIA Ch9)
- [ ] Implement circuit breaker pattern (tenacity library) for LLM calls
- [ ] Add dead-letter queue processing for failed events
- [ ] Implement exponential backoff with jitter on retries
- [ ] Add timeout budgets per request (propagate remaining time across services)
- [ ] Implement graceful shutdown for all services (drain connections, finish in-flight)
- [ ] Add Pod Disruption Budgets (PDB) for all deployments

### 2.2 Data Integrity (DDIA Ch8)
- [ ] Implement transactional outbox relay (poll + publish to Redpanda)
- [ ] Add idempotency keys to all event consumers (dedup by event_id)
- [ ] Implement saga pattern for multi-service transactions (e.g., subscription + user upgrade)
- [ ] Add database migration rollback procedures
- [ ] Implement read-replica routing for read-heavy queries

### 2.3 Disaster Recovery
- [ ] Set up automated PostgreSQL backups (pg_dump + S3)
- [ ] Implement point-in-time recovery (PITR) with WAL archiving
- [ ] Document and test recovery runbook
- [ ] Implement Redpanda topic backup strategy
- [ ] Create disaster recovery playbook

---

## 🟢 Priority 3: Performance Optimization

### 3.1 Database Performance (DDIA Ch4)
- [ ] Benchmark pgvector index types: IVFFlat vs HNSW (use HNSW for production)
- [ ] Implement connection pooling with PgBouncer
- [ ] Add read replicas for assessment queries
- [ ] Optimize TimescaleDB continuous aggregates for analytics dashboards
- [ ] Implement query result caching (Redis) for frequently accessed data
- [ ] Partition assessment_results table by month

### 3.2 API Performance
- [ ] Implement response caching (Redis) for static endpoints
- [ ] Add HTTP/2 support on Ingress
- [ ] Implement pagination on all list endpoints
- [ ] Add database query optimization (EXPLAIN ANALYZE on critical paths)
- [ ] Implement async batch operations for bulk data loads

### 3.3 AI Cost Optimization
- [ ] Implement prompt caching (hash prompt → cache response in Redis)
- [ ] Add token usage tracking per user (for billing)
- [ ] Implement request batching for AI worker (process N events per LLM call)
- [ ] Add model response quality scoring (auto-detect poor responses, retry with better model)
- [ ] Implement streaming responses for real-time quiz generation

---

## 🔵 Priority 4: Observability & Operations

### 4.1 Monitoring (DDIA Ch2)
- [ ] Instrument all services with OpenTelemetry SDK
- [ ] Deploy Prometheus + Grafana stack
- [ ] Create service health dashboard (RED metrics: Rate, Errors, Duration)
- [ ] Create AI cost tracking dashboard (tokens used, cost per model, per user)
- [ ] Create business metrics dashboard (DAU, conversion rate, churn)
- [ ] Implement SLOs: p99 < 200ms API, p99 < 5s AI worker, 99.9% uptime

### 4.2 Logging
- [ ] Implement structured JSON logging (all services)
- [ ] Add correlation IDs across all services (trace-id in headers)
- [ ] Deploy log aggregation (Loki or ELK)
- [ ] Add log-based alerting for critical errors

### 4.3 Alerting
- [ ] Consumer lag > threshold → alert (KEDA + Prometheus)
- [ ] Error rate > 1% → alert
- [ ] p99 latency > SLO → alert
- [ ] LLM provider outage detection → auto-failover + alert
- [ ] Payment failure rate > threshold → alert
- [ ] Disk usage > 80% → alert

---

## 🟣 Priority 5: Feature Enhancements

### 5.1 Learning Engine
- [ ] Implement spaced repetition algorithm for quiz scheduling
- [ ] Add difficulty auto-calibration based on user performance
- [ ] Implement learning streak tracking and gamification
- [ ] Add multi-language support for quiz content
- [ ] Implement collaborative filtering (recommend paths based on similar users)
- [ ] Add skill gap analysis compared to job market requirements

### 5.2 AI Capabilities
- [ ] Implement RAG with hybrid search (vector + keyword + temporal)
- [ ] Add document chunking pipeline for learning material ingestion
- [ ] Implement AI-powered code review for coding assessments
- [ ] Add real-time feedback during quiz (explain wrong answers)
- [ ] Implement career path prediction based on skill trajectory

### 5.3 User Experience
- [ ] Add WebSocket support for real-time quiz interactions
- [ ] Implement progress notifications (email + push)
- [ ] Add team/organization features for Enterprise tier
- [ ] Implement skill certification generation (PDF)
- [ ] Add API for third-party integrations (LinkedIn, GitHub)

### 5.4 Billing Enhancements
- [ ] Implement coupon/discount system
- [ ] Add usage-based pricing tier (pay per AI query)
- [ ] Implement team billing for Enterprise
- [ ] Add invoice PDF generation
- [ ] Implement refund workflow

---

## 🏗️ Priority 6: Infrastructure Evolution

### 6.1 Kubernetes Production Readiness
- [ ] Implement Horizontal Pod Autoscaler (HPA) for API services
- [ ] Configure KEDA ScaledObjects for AI Worker and CV Analyzer
- [ ] Set resource requests/limits on all pods
- [ ] Implement rolling update strategy (maxSurge: 1, maxUnavailable: 0)
- [ ] Add init containers for dependency health checks
- [ ] Implement namespace isolation (per environment)

### 6.2 GitOps & IaC
- [ ] Implement ArgoCD or FluxCD for GitOps deployments
- [ ] Complete Terraform modules for cloud infrastructure
- [ ] Add Terratest for infrastructure testing
- [ ] Implement environment promotion pipeline (dev → staging → prod)

### 6.3 Future: On-Premise AI
- [ ] Deploy vLLM for self-hosted LLM inference
- [ ] Configure LiteLLM to route to local vLLM endpoint
- [ ] Benchmark cost savings vs cloud LLM APIs
- [ ] Implement GPU node pool auto-scaling

---

## 🧪 Priority 7: Next-Gen Features (from Brainstorm)

### 7.1 Gamified Skill Tree ("Hidden Competency Graph")
- [ ] Build interactive skill tree visualization (video game-style tech tree)
- [ ] Initially show only the user's current domain branches
- [ ] Unlock hidden branches as user answers "stealth questions" successfully
- [ ] Each node = a skill with progress bar and confidence score
- [ ] Animate new branch unlocks (dopamine-driven engagement)
- [ ] Show career paths unlocked by reaching skill milestones

### 7.2 Market-Driven Nudging (Job Market Intelligence)
- [ ] Nightly scraper for job postings (LinkedIn/Indeed/Glassdoor APIs)
- [ ] Extract in-demand skills from job descriptions (LLM extraction)
- [ ] Cross-reference user's competency vector with market demand
- [ ] If user has aptitude for high-demand role → inject stealth questions in that domain
- [ ] "Career Opportunity" dashboard: show matching jobs + skill gaps
- [ ] Alert user: "Cloud Architect roles pay 30% more and you're 70% there"

### 7.3 Voice Challenges (Interview Simulator)
- [ ] Weekly "Voice Challenge" — user explains a concept via audio
- [ ] Speech-to-text (Whisper API or browser Web Speech API)
- [ ] AI analysis of: clarity, confidence, technical accuracy, structure
- [ ] Soft skill scoring (leadership, communication, presentation)
- [ ] Mock interview mode with AI interviewer (multi-turn voice conversation)
- [ ] Generate feedback report with improvement suggestions

### 7.4 AI Chat & User Intelligence (Passive Profiling)
- [x] Chat service (WebSocket real-time AI conversation) — scaffolded
- [x] User Intelligence Worker (analyze chat to extract skills) — scaffolded
- [ ] Implement conversation analysis pipeline (batch 5-10 messages → LLM extraction)
- [ ] Build communication profile (vocabulary level, technical density, confidence)
- [ ] Cross-service intelligence (merge chat + quiz + CV + behavior signals)
- [ ] Implement weighted moving average for competency vector updates
- [ ] Add opt-in consent for conversation analysis (GDPR)

---

---

## 🌟 Priority 8: The Brilliance Tier (Platform Differentiators)

### 8.1 Peer-to-Peer Mock Interviews
- [ ] Matchmaking algorithm based on complementary skill gaps (e.g., strong backend + weak frontend meets strong frontend + weak backend)
- [ ] WebRTC logic for live audio/video communication
- [ ] Integrated collaborative code editor during the interview
- [ ] AI runs in the background to transcribe and analyze the interview
- [ ] Automated constructive feedback generation based on peer grading + AI analysis

### 8.2 Quest & Bounty System (Real-World Application)
- [ ] Scrape "Good First Issues" from GitHub open-source projects
- [ ] Package them as "Bounties" inside the platform
- [ ] Users earn XP, unlock skill tree branches, and build a real portfolio
- [ ] AI reviews the PR draft before the user officially submits it to the repo
- [ ] Leaderboards based on successfully merged bounties

### 8.3 NoSQL/JSONB Hyper-Personalization
- [ ] Shift rigid UI layouts to dynamic templates stored in `user_dynamic_state.ui_preferences`
- [ ] AI dynamically reconfigures the UI based on learning style (visual learners get more diagrams, text learners get deep explanations)
- [ ] Mental State / Burnout Detection: AI worker analyzes study patterns to detect fatigue
- [ ] If burnout detected → AI forces a "light day" (e.g., just watch a 5-min video instead of a hard quiz)
- [ ] Update gamification engine to run entirely out of JSONB state (easy schema iteration without migrations)

---

## 📋 Technical Debt Tracker

| Item | Priority | Status |
|------|----------|--------|
| Add actual test files to all services | High | 🔴 |
| Pin all Python dependency versions | High | 🔴 |
| Add pre-commit hooks (ruff + black + isort) | Medium | 🔴 |
| Set up git tag-based versioning | Medium | 🔴 |
| Add API versioning (v1/) to all endpoints | Medium | 🔴 |
| Create shared Pydantic models in py-common | Medium | 🔴 |
| Document all environment variables | Low | 🔴 |
| Add OpenAPI spec to docs/api/ | Low | 🔴 |
