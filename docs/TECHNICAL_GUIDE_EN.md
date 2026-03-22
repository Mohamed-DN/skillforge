# SkillForge: Technical Implementation Guide

> **Objective:** A comprehensive, step-by-step operating procedure for deploying SkillForge, an AI-driven, event-sourced EdTech platform.
> **Architecture:** 12 Microservices, Kubernetes (HA), PostgreSQL (pgvector/TimescaleDB), Redpanda (Kafka), and LiteLLM.
> **Principle:** Zero-Cost Development → Full-Stack High Availability Production.

---

## Part 1: Architecture & Dual-Environment Strategy

SkillForge is designed with a **Dual Strategy**: completely free local development, transitioning to a bank-grade, highly available production environment where costs are strictly allocated to high-value components (Compute and AI inference).

### Comparison: Local Dev vs. Production (Full-Stack HA)

| Component | 🛠️ Local Development (Zero Cost) | 🚀 Production (Full-Stack HA) | Rationale for Production Setup |
|-----------|---------------------------|----------------------------------------|---------------------------------|
| **Compute** | Local Podman/Docker Compose | **Managed K8s (DOKS/Linode)** + HPA | Offloads control plane management. Horizontal Pod Autoscaling (HPA) ensures pods scale across 3+ physical nodes dynamically. |
| **Database**| Single PostgreSQL Container | **3-Node HA Postgres Cluster** | Self-managed via **CloudNativePG**. 1 Primary, 1 Sync Standby, 1 Async DR. Eliminates expensive managed DB fees while maintaining 99.99% uptime. |
| **Event Bus**| Single Redpanda Container | **3-Broker Redpanda Cluster** | Raft consensus guarantees zero message loss. If one K8s host fails, the other two brokers maintain quorum. |
| **Storage** | Single MinIO Container | **Distributed MinIO (Erasure Coding)** | S3-compatible. Erasure coding across 4+ drives ensures data integrity even if entire disks or nodes are lost. |
| **AI Router**| Local Open-Weight (Llama-3)| **HA Hybrid Router (LiteLLM)** | Routes complex tasks to Claude 3.5/GPT-4o and simpler tasks to DeepSeek. Built-in automatic failovers prevent AI downtime. |

## Part 2: Step-by-Step Implementation

### Step 1: Database Initialization
Deploy PostgreSQL 16 equipped with both `pgvector` (for 1536-dimensional AI embeddings) and `TimescaleDB` (for time-series audit logs and chat histories).
Ensure the `schema.sql` (containing all 22 core tables) is injected upon initialization.

### Step 2: Authentication Service (Bank-Grade Security)
Build the `auth-service` using FastAPI. 
1. Use `bcrypt` for password hashing (cost factor 12+).
2. Implement Asymmetric JWT (RS256). The auth service holds the private key to sign tokens; other services use the public key to verify them without network calls.
3. Integrate RBAC (Learner, Premium, Admin) and store active sessions in Redis for instant revocation.

### Step 3: Global API Gateway & Rate Limiting
Deploy `api-gateway` as the single public entry point.
1. Implement Redis-based rate limiting to prevent DDoS.
2. Centralize JWT verification.
3. Establish strict timeout policies and OpenTelemetry tracing injection.

### Step 4: Kappa Architecture (The Event Bus)
Deploy Redpanda. All state changes in the system (e.g., `UserRegistered`, `CourseCompleted`, `ChatMessageSent`) must be published as Protobuf-serialized events to Redpanda. 
Microservices consume these events to update their local materialized views or trigger asynchronous workflows.

### Step 5: AI Abstraction (LiteLLM)
Never hardcode API keys for OpenAI/Anthropic in application logic. 
Deploy LiteLLM as a central router (`llm-gateway`). Configure fallback chains (e.g., if Claude fails, fallback to GPT-4o). 

### Step 6: The Passive Intelligence Worker
Deploy the `user-intelligence-worker`. This service silently consumes chat events and assessment events from Redpanda. It uses the `llm-gateway` to extract personality traits, skill gaps, and learning styles, constantly updating the user's `JSONB` profile in PostgreSQL.

### Step 7: Career Advisor & Gamification
Develop the `career-advisor-service` which matches the user's `pgvector` competency embeddings against real-world job market requirements.
Implement gamification quests based on the identified skill gaps to naturally "nudge" the user toward high-value market skills.

### Step 8: Billing (Stripe Integration)
Implement the `billing-service` to handle Stripe Checkout sessions and webhooks. 
Ensure idempotency when processing Stripe webhooks to avoid double-upgrades during network retries.

### Step 9: CV Parsing (Async Worker)
Deploy the `cv-analyzer`. When a user uploads a CV (stored in MinIO), the API gateway publishes a `CvUploaded` event. The analyzer consumes the event, extracts text from the PDF/DOCX, and uses the AI router to generate the initial competency vectors.

### Step 10: Security Hardening (Zero-Trust)
1. **Network Policies**: By default, no pod can talk to another pod in Kubernetes. Explicitly whitelist traffic (e.g., only API Gateway can talk to Auth Service).
2. **mTLS**: Implement a service mesh (like Linkerd or Istio) to encrypt all pod-to-pod traffic.
3. **Secrets**: Move all credentials out of `.env` files and into HashiCorp Vault or Kubernetes external secrets.

### Step 11: Production Deployment (Full-Stack HA & Autoscaling)
To transition from development to production:
1. **Compute (Two-Level Autoscaling)**: 
   - Deploy microservices using `HorizontalPodAutoscaler` targeting 80% CPU.
   - Enable **Cluster Autoscaler** (or Karpenter) so the cloud provider dynamically adds/removes physical nodes based on aggregate pod demand.
2. **Postgres HA**: Apply the CloudNativePG `cluster.yaml` with `instances: 3`.
3. **Redpanda HA**: Deploy via Helm chart enforcing `replicas: 3` and pod anti-affinity.
4. **MinIO HA**: Deploy the MinIO Operator with erasure coding enabled across the physical node volumes.

## Part 3: Financial Projections & API Safeguards

### API Margin Safeguards (Zero-Loss Guarantee)
To prevent a $9.99/mo user from consuming $50 in LLM tokens:
1. **Model Fallbacks**: LiteLLM routes ~90% of passive background tasks to extremely cheap models (e.g., DeepSeek-V3).
2. **Hard Budgets**: The DB maintains an `api_token_budget_month` column for each user. LiteLLM strictly enforces this budget. Once a user hits their allocated API cost (e.g., $2.00 API cost limit on a $9.99 subscription), AI features gracefully degrade or prompt an upgrade. Users **cannot** mathematically cause an operational loss.

### Scaling to 1M Users
Operating an EdTech platform with Full-Stack HA infrastructure yields massive margins at scale by minimizing managed-cloud overhead.

| User Target | Infrastructure Setup | Approx. Monthly OPEX | Paying Users (5%) | Net Revenue | **Net Profit (EBITDA)** |
|-------------|----------------------|----------------------|-------------------|-------------|-------------------------|
| **100** | Bare minimum HA cluster (3x 2GB nodes) | ~$50 | 5 | ~$66 | **~$16** |
| **1,000** | Standard HA cluster (3x 4GB/8GB nodes)| ~$100 | 50 | ~$660 | **~$560** (85% Margin)|
| **10,000** | Enhanced nodes (5x 16GB) + AI API costs | ~$300 | 500 | ~$6,600 | **~$6,300** (95% Margin)|
| **100,000** | 10+ High-end nodes, heavy DB sharding | ~$2,000 | 5,000 | ~$66,000 | **~$64,000** (97% Margin)|
| **1,000,000**| Fleet of DOKS servers, massive AI inference| ~$12,000 | 50,000 | ~$660,000| **~$648,000** 💸🚀 |

*By self-hosting the core components (DB, Kafka, Object Storage) via Cloud-Native K8s operators, the platform avoids the 40%+ margin tax typical of fully managed cloud ecosystems at hyperscale.*
