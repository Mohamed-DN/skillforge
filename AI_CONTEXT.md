# 🤖 AI Context — SkillForge (Next-Gen Version)

> **This file is for AI assistants** (Claude, Gemini, GPT, Copilot, etc.).
> It provides the core context needed to understand the brilliant vision of this project and contribute effectively.

---

## 🌟 The Vision: "The Holy Grail of EdTech"

SkillForge is not just another LMS (Learning Management System). It is a **predictive, adaptive AI career engine** that uses stealth profiling, gamification, and market intelligence to guide users to their maximum potential. 

1. **Passive Intelligence**: The system learns about the user through *every* interaction—how fast they answer, their vocabulary in chat, their code syntax.
2. **Hidden Skill Tree**: A video-game style tech tree. Users start with visible branches for their current role, but hidden branches (like *System Design* or *Cloud Architecture*) illuminate as the AI detects latent talents.
3. **Market-Driven Nudging**: The system scrapes the job market. If Kubernetes engineers are in high demand and the user has a 70% vector match, the AI subtly injects Kubernetes "stealth questions" into their daily learning to nudge them towards that high-paying career.
4. **Voice & Peer Challenges**: We don't just do text. We do AI-driven Voice Interviews (Web Speech API) to grade soft skills and confidence, and we match users peer-to-peer for mock interviews based on complementary skill gaps.

---

## 🏛️ Project Identity & Tech Stack

- **Name**: SkillForge
- **Architecture**: Event-driven microservices (12 services) on Kubernetes
- **Container Engine**: Podman (rootless, daemonless — bank-level security)
- **Primary Language**: Python 3.12+ (FastAPI)
- **Key Book Reference**: *"Designing Data-Intensive Applications"* v2 
- **Database Philosophy (The Hybrid Absolute)**:
  - We use **PostgreSQL** as our universal data engine.
  - **Relational (ACID)**: For users, billing, auth.
  - **Vector (pgvector)**: For AI RAG, semantic search, and user competency vectors (1536-dim).
  - **Time-Series (TimescaleDB)**: For tracking skill progression and chat histories over time.
  - **NoSQL / Flexible (JSONB)**: For deeply nested, highly dynamic unstructured data (active hours, learning styles, complex AI analysis reports, gamification states) avoiding rigid schema changes.
- **Production Paradigm (Full-Stack HA)**: 
  - Zero Single Points of Failure. 
  - 3-Node HA PostgreSQL (User DBA managed), 3-Broker Redpanda (Raft Consensus), Distributed MinIO (Erasure Coding), and HPA scaled microservices.
- **Security Level**: Bank-grade (mTLS, encryption at rest + transit, GDPR, audit logs)

---

## 🧩 Architecture Overview (12 Microservices)

| Service | Port | Role |
|---------|------|------|
| `api-gateway` | 8000 | Public REST API, routing, JWT validation |
| `auth-service` | 8005 | OAuth2, RS256 JWT, bcrypt, MFA, RBAC |
| `billing-service` | 8006 | Stripe subscriptions, PCI-compliant billing |
| `chat-service` | 8007 | WebSocket real-time AI conversation, streaming responses |
| `llm-gateway` | 8001 | LiteLLM abstraction layer (routes to DeepSeek/Gemini/OpenAI) |
| `ai-worker` | — | Redpanda consumer, handles async RAG & data derivation |
| `user-intelligence-worker` | — | **The Brain**: Analyzes chats/quizzes to build psychological & skill profiles |
| `assessment-engine` | 8002 | Generates adaptive quizzes with RAG |
| `career-advisor-service` | 8008 | Compares user skills to job offers, generates 30-day study plans |
| `user-profile-service` | 8003 | CRUD for user identity, goals, and core domain |
| `cv-analyzer` | — | CV parsing worker (PDF/DOCX extraction) |
| `notification-service` | 8004 | Push/email notifications, dopamine-driven engagement |

---

## ⚙️ Key System Mechanics

1. **Kappa Architecture (Stream First)**: Every interaction (button click, chat message, quiz answer) is an immutable event published to **Redpanda**. Workers consume these events, process them, and update Postgres in real-time.
2. **Idempotency**: All workers track processed `event_id`s in Redis/Postgres to ensure exactly-once processing semantics.
3. **LLM Agnosticism**: We never hardcode OpenAI or Gemini. Everything goes through `llm-gateway` (LiteLLM) for intelligent fallback, cost routing, and prompt caching.
4. **Zero-Trust Security**: No service trusts another by default. Requests are verified via signed JWTs (RS256), and Kubernetes network policies block default traffic. No credentials ever exist in the codebase (Vault).

---

## 🚀 Current Progress

> **Last updated**: 2026-03-22

- ✅ **Scaffolding Complete**: All 12 services created.
- ✅ **Database Complete**: Schema with 22 tables (including NoSQL `JSONB` columns for insights and plans, `pgvector`, `TimescaleDB` hypertables).
- ✅ **Events Complete**: Protobuf schema (`events.proto`) with 25 event types spanning users, auth, chat, AI, and career modules.
- ✅ **CI/CD Active**: GitHub Actions matrix configured for all 12 services, including Trivy security scanning.
- ✅ **Internal Docs**: `PERSONAL_GUIDE.md` completely documents how to build the platform from zero to prod.
- 🟡 **Implementation Phase**: Developing core business logic inside the microservice endpoints.

---

## 💡 How to Help

When asked to implement a feature:
1. Prefer event-driven approaches (publish event to Redpanda -> consume in worker) over synchronous API calls where possible.
2. Use Postgres `JSONB` for unstructured metadata to keep schemas flexible.
3. Keep security in mind: use absolute paths, secure dependencies, and validate all inputs.
4. If a feature interacts with the AI, route it through the `llm-gateway`, never directly to an LLM provider.
