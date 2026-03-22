# Career Advisor Service

AI-powered career coaching engine. Users paste a job offer and the system cross-references it with their profile to produce a personalized action plan: what to study, how to improve their CV, and how to stand out from other candidates.

## How It Works

```
Job Offer (text/URL)
        │
        ▼
┌──────────────────────┐
│  Career Advisor Svc  │──→ LLM Gateway ──→ AI Analysis
└──────────────────────┘
        │                         │
        ▼                         ▼
  User Profile (pgvector)    Market Intelligence
  Competency Vectors          Job Requirements
  Chat Insights               Salary Benchmarks
        │
        ▼
┌──────────────────────────────────────────────┐
│               OUTPUT                          │
│                                               │
│  📊 Skill Gap Analysis                       │
│     "You have 7/10 required skills"          │
│     "Missing: Terraform, Kafka, Go"          │
│                                               │
│  📝 CV Improvements                          │
│     "Add quantified results to experience"   │
│     "Reorder sections: skills first"         │
│     "Add keywords: 'distributed systems'"    │
│                                               │
│  🎯 Stand-Out Strategy                       │
│     "Build a public demo of X"               │
│     "Get AWS certification (high demand)"    │
│     "Contribute to open-source Kafka"        │
│                                               │
│  📅 30-Day Study Plan                        │
│     "Week 1: Terraform basics → project"     │
│     "Week 2: Kafka deep dive + lab"          │
│     "Week 3: Go crash course"                │
│     "Week 4: Mock interviews + CV polish"    │
└──────────────────────────────────────────────┘
```

## Features

### 1. Job Offer Parser
- Paste raw text or URL of a job posting
- AI extracts: required skills, nice-to-have skills, seniority level, tech stack, soft skills
- Normalizes skill names to match internal taxonomy

### 2. Gap Analysis (pgvector)
- Compares extracted job requirements against user's `competency_vectors`
- Calculates match percentage per skill and overall
- Identifies: ✅ Skills you have, ⚠️ Skills to improve, ❌ Skills to learn

### 3. CV Optimizer
- Cross-references job requirements with user's CV data
- Suggests keyword additions (ATS optimization)
- Recommends structural changes (ordering, emphasis)
- Generates a tailored CV summary for that specific role
- Suggests quantified achievements to add

### 4. Stand-Out Strategy
- Analyzes what differentiates strong candidates for this role
- Suggests portfolio projects, certifications, contributions
- Recommends networking actions (communities, events)
- Tailored cover letter draft generation

### 5. Personalized Study Plan
- 30-day or 60-day plan to close skill gaps
- Prioritized by: impact on role match, learning difficulty, market value
- Daily tasks with estimated time commitment
- Integrated with SkillForge quiz system (auto-generates quizzes on gap areas)

### 6. Job Tracker
- Save job offers for comparison
- Track application status (saved, applied, interview, offer, rejected)
- Side-by-side comparison of multiple offers
- Salary range estimation based on skills + market data

## Events Produced
| Event | Topic | Trigger |
|-------|-------|---------|
| `JobOfferAnalyzed` | `career.job.analyzed` | Job offer parsed and analyzed |
| `SkillGapIdentified` | `career.gap.identified` | Gap analysis completed |
| `StudyPlanGenerated` | `career.plan.generated` | Study plan created |
| `CVOptimized` | `career.cv.optimized` | CV suggestions generated |

## API Endpoints
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/career/analyze` | Analyze a job offer against user profile |
| `GET` | `/career/gaps` | Get current skill gaps |
| `POST` | `/career/cv/optimize` | Get CV improvement suggestions for a specific job |
| `POST` | `/career/study-plan` | Generate personalized study plan |
| `POST` | `/career/cover-letter` | Generate tailored cover letter |
| `GET` | `/career/jobs` | List saved job offers |
| `POST` | `/career/jobs` | Save a job offer |
| `PATCH` | `/career/jobs/:id` | Update application status |
| `GET` | `/career/jobs/compare` | Compare multiple saved offers |
| `DELETE` | `/career/jobs/:id` | Delete saved job offer |

## Tech
- FastAPI + Uvicorn
- LiteLLM (analysis via LLM Gateway)
- pgvector (skill matching against competency vectors)
- SQLAlchemy (job offers, study plans)
- httpx (optional: scrape job URLs)

## Running
```bash
cd services/career-advisor-service
pip install -r requirements.txt
uvicorn src.main:app --reload --port 8008
```
