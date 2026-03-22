-- =============================================================
-- SkillForge Database Schema (Reference)
-- PostgreSQL + pgvector + TimescaleDB
-- Bank-Level Security: Encrypted fields, audit log, GDPR
-- =============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";         -- pgvector
CREATE EXTENSION IF NOT EXISTS "timescaledb";    -- TimescaleDB
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- Encryption functions

-- =============================================================
-- USERS (Core identity)
-- =============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    role            VARCHAR(50) DEFAULT 'learner',  -- learner, premium, admin
    career_goal     VARCHAR(255),
    current_role    VARCHAR(255),
    experience_years INTEGER DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    email_verified  BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- =============================================================
-- USER CREDENTIALS (Separated for security — never SELECT *)
-- =============================================================
CREATE TABLE user_credentials (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash   VARCHAR(255) NOT NULL,           -- bcrypt, cost 12+
    mfa_secret      BYTEA,                           -- Encrypted TOTP secret
    mfa_enabled     BOOLEAN DEFAULT FALSE,
    failed_attempts INTEGER DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    last_login      TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- =============================================================
-- GDPR CONSENT RECORDS
-- =============================================================
CREATE TABLE gdpr_consent (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type    VARCHAR(100) NOT NULL,            -- 'data_processing', 'marketing', 'analytics'
    granted         BOOLEAN NOT NULL,
    granted_at      TIMESTAMPTZ,
    revoked_at      TIMESTAMPTZ,
    ip_address      INET,                             -- IP at time of consent
    user_agent      TEXT,                              -- Browser info at time of consent
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_consent_user ON gdpr_consent(user_id);

-- =============================================================
-- SUBSCRIPTIONS (Billing)
-- =============================================================
CREATE TABLE subscriptions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tier            VARCHAR(20) NOT NULL DEFAULT 'free', -- free, pro, enterprise
    billing_cycle   VARCHAR(20),                      -- monthly, annual
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    status          VARCHAR(20) DEFAULT 'active',     -- active, trialing, past_due, canceled
    trial_end       TIMESTAMPTZ,
    current_period_start TIMESTAMPTZ,
    current_period_end   TIMESTAMPTZ,
    canceled_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX idx_subscriptions_stripe ON subscriptions(stripe_customer_id);

-- =============================================================
-- INVOICES
-- =============================================================
CREATE TABLE invoices (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id),
    stripe_invoice_id VARCHAR(255),
    amount_cents    INTEGER NOT NULL,
    currency        VARCHAR(3) DEFAULT 'EUR',
    status          VARCHAR(20) NOT NULL,             -- paid, open, void, draft
    paid_at         TIMESTAMPTZ,
    invoice_url     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_invoices_user ON invoices(user_id);

-- =============================================================
-- COMPETENCY VECTORS (pgvector)
-- =============================================================
CREATE TABLE competency_vectors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    embedding       vector(1536) NOT NULL,
    domain          VARCHAR(100) NOT NULL,
    confidence      FLOAT DEFAULT 0.0,
    last_updated_by VARCHAR(255),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, domain)
);

CREATE INDEX idx_competency_vectors_user ON competency_vectors(user_id);
CREATE INDEX idx_competency_vectors_embedding ON competency_vectors
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- =============================================================
-- ASSESSMENTS
-- =============================================================
CREATE TABLE assessments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    domain          VARCHAR(100) NOT NULL,
    difficulty      VARCHAR(20) DEFAULT 'medium',
    question_count  INTEGER DEFAULT 10,
    time_limit_sec  INTEGER DEFAULT 600,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE assessment_questions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id   UUID REFERENCES assessments(id) ON DELETE CASCADE,
    question_text   TEXT NOT NULL,
    question_type   VARCHAR(20) NOT NULL,
    options         JSONB,
    correct_answer  TEXT,
    domain          VARCHAR(100) NOT NULL,
    difficulty      VARCHAR(20) DEFAULT 'medium',
    is_stealth      BOOLEAN DEFAULT FALSE,
    embedding       vector(1536),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_questions_assessment ON assessment_questions(assessment_id);
CREATE INDEX idx_questions_domain ON assessment_questions(domain);
CREATE INDEX idx_questions_embedding ON assessment_questions
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- =============================================================
-- ASSESSMENT RESULTS
-- =============================================================
CREATE TABLE assessment_results (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assessment_id   UUID NOT NULL REFERENCES assessments(id),
    question_id     UUID NOT NULL REFERENCES assessment_questions(id),
    user_answer     TEXT,
    is_correct      BOOLEAN,
    response_time_ms INTEGER,
    confidence_score FLOAT,
    ai_analysis     JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_results_user ON assessment_results(user_id);

-- =============================================================
-- LEARNING MATERIALS (pgvector for RAG)
-- =============================================================
CREATE TABLE learning_materials (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(500) NOT NULL,
    source          VARCHAR(255),
    content_chunk   TEXT NOT NULL,
    chunk_index     INTEGER DEFAULT 0,
    domain          VARCHAR(100) NOT NULL,
    tags            TEXT[],
    embedding       vector(1536) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_materials_domain ON learning_materials(domain);
CREATE INDEX idx_materials_embedding ON learning_materials
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 200);

-- =============================================================
-- LEARNING PATHS
-- =============================================================
CREATE TABLE learning_paths (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    path_data       JSONB NOT NULL,
    generated_by    VARCHAR(255),
    version         INTEGER DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_paths_user ON learning_paths(user_id);

-- =============================================================
-- USER PROGRESS (TimescaleDB hypertable)
-- =============================================================
CREATE TABLE user_progress (
    time            TIMESTAMPTZ NOT NULL,
    user_id         UUID NOT NULL,
    metric_type     VARCHAR(50) NOT NULL,
    domain          VARCHAR(100),
    value           FLOAT NOT NULL,
    metadata        JSONB
);

SELECT create_hypertable('user_progress', 'time');
CREATE INDEX idx_progress_user_time ON user_progress(user_id, time DESC);
CREATE INDEX idx_progress_metric ON user_progress(metric_type, time DESC);

-- =============================================================
-- AUDIT LOG (Immutable — GDPR, bank-level compliance)
-- =============================================================
CREATE TABLE audit_log (
    time            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actor_id        UUID,                             -- Who did it (user or system)
    actor_type      VARCHAR(50) NOT NULL,             -- 'user', 'system', 'admin'
    action          VARCHAR(100) NOT NULL,            -- 'login', 'data_export', 'data_delete', etc.
    resource_type   VARCHAR(100),                     -- 'user', 'subscription', 'assessment'
    resource_id     UUID,
    details         JSONB,                            -- Additional context
    ip_address      INET,
    user_agent      TEXT,
    success         BOOLEAN DEFAULT TRUE
);

SELECT create_hypertable('audit_log', 'time');
CREATE INDEX idx_audit_actor ON audit_log(actor_id, time DESC);
CREATE INDEX idx_audit_action ON audit_log(action, time DESC);

-- =============================================================
-- EVENTS OUTBOX (Transactional Outbox Pattern)
-- =============================================================
CREATE TABLE events_outbox (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type      VARCHAR(100) NOT NULL,
    aggregate_type  VARCHAR(100) NOT NULL,
    aggregate_id    UUID NOT NULL,
    payload         JSONB NOT NULL,
    published       BOOLEAN DEFAULT FALSE,
    published_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_outbox_unpublished ON events_outbox(published, created_at)
    WHERE published = FALSE;

-- =============================================================
-- CHAT SESSIONS
-- =============================================================
CREATE TABLE chat_sessions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(255),
    topic           VARCHAR(50) DEFAULT 'general',    -- general, technical, career
    status          VARCHAR(20) DEFAULT 'active',     -- active, ended, archived
    message_count   INTEGER DEFAULT 0,
    summary         TEXT,                              -- AI-generated conversation summary
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    ended_at        TIMESTAMPTZ
);

CREATE INDEX idx_chat_sessions_user ON chat_sessions(user_id, created_at DESC);

-- =============================================================
-- CHAT MESSAGES (TimescaleDB for efficient time-range queries)
-- =============================================================
CREATE TABLE chat_messages (
    time            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_id      UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL,
    role            VARCHAR(20) NOT NULL,              -- 'user', 'assistant', 'system'
    content         TEXT NOT NULL,
    token_count     INTEGER,
    model_used      VARCHAR(100),                      -- which LLM was used
    response_time_ms INTEGER,                          -- how long the AI took to respond
    metadata        JSONB                              -- additional context
);

SELECT create_hypertable('chat_messages', 'time');
CREATE INDEX idx_chat_messages_session ON chat_messages(session_id, time ASC);
CREATE INDEX idx_chat_messages_user ON chat_messages(user_id, time DESC);

-- =============================================================
-- USER INSIGHTS (Extracted by User Intelligence Worker)
-- =============================================================
CREATE TABLE user_insights (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    insight_type    VARCHAR(50) NOT NULL,              -- 'skill_detected', 'gap_detected', 'interest', 'style'
    category        VARCHAR(100),                      -- e.g., 'python', 'kubernetes', 'communication'
    value           TEXT NOT NULL,                     -- the actual insight
    confidence      FLOAT DEFAULT 0.0,                 -- 0.0 to 1.0
    source          VARCHAR(50) NOT NULL,              -- 'chat', 'quiz', 'cv', 'behavior'
    source_ref      UUID,                              -- reference to source (session_id, assessment_id)
    evidence        JSONB,                             -- supporting data points
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_insights_user ON user_insights(user_id);
CREATE INDEX idx_insights_type ON user_insights(user_id, insight_type);

-- =============================================================
-- COMMUNICATION PROFILE (Language & interaction analysis)
-- =============================================================
CREATE TABLE communication_profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vocabulary_level VARCHAR(20),                      -- 'beginner', 'intermediate', 'advanced', 'expert'
    avg_response_length FLOAT,                         -- average words per message
    technical_density FLOAT,                           -- ratio of technical terms
    primary_language VARCHAR(10),                      -- detected language (ISO 639-1)
    communication_style VARCHAR(50),                   -- 'concise', 'detailed', 'questioning', 'structured'
    confidence_level VARCHAR(20),                      -- 'uncertain', 'moderate', 'confident', 'expert'
    preferred_topics TEXT[],                            -- most discussed topics
    active_hours     JSONB,                            -- hourly activity distribution
    learning_style  VARCHAR(50),                       -- 'visual', 'reading', 'interactive', 'mixed'
    engagement_score FLOAT DEFAULT 0.0,                -- 0.0 to 1.0
    last_analyzed_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- =============================================================
-- JOB OFFERS (Career Advisor — saved for analysis)
-- =============================================================
CREATE TABLE job_offers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    company         VARCHAR(255),
    location        VARCHAR(255),
    salary_min      INTEGER,
    salary_max      INTEGER,
    currency        VARCHAR(3) DEFAULT 'EUR',
    seniority       VARCHAR(50),                       -- junior, mid, senior, lead
    raw_text        TEXT NOT NULL,                      -- original job posting
    required_skills TEXT[],                             -- AI-extracted
    nice_to_have    TEXT[],                             -- AI-extracted
    soft_skills     TEXT[],                             -- AI-extracted
    match_score     FLOAT,                             -- 0.0-1.0 match with user
    application_status VARCHAR(30) DEFAULT 'saved',    -- saved, applied, interview, offer, rejected
    ai_analysis     JSONB,                             -- full AI analysis result
    applied_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_job_offers_user ON job_offers(user_id, created_at DESC);
CREATE INDEX idx_job_offers_status ON job_offers(user_id, application_status);

-- =============================================================
-- JOB SKILL GAPS (per job offer, what the user needs to learn)
-- =============================================================
CREATE TABLE job_skill_gaps (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_offer_id    UUID NOT NULL REFERENCES job_offers(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_name      VARCHAR(100) NOT NULL,
    user_level      FLOAT DEFAULT 0.0,                 -- 0.0-1.0 current user level
    required_level  FLOAT DEFAULT 0.5,                 -- 0.0-1.0 job requirement
    gap_severity    VARCHAR(20),                        -- low, medium, high, critical
    priority        INTEGER DEFAULT 0,                  -- learning priority order
    study_hours_est INTEGER,                            -- estimated hours to close gap
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gaps_job ON job_skill_gaps(job_offer_id);
CREATE INDEX idx_gaps_user ON job_skill_gaps(user_id);

-- =============================================================
-- STUDY PLANS (AI-generated learning plans for job targets)
-- =============================================================
CREATE TABLE study_plans (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_offer_id    UUID REFERENCES job_offers(id) ON DELETE SET NULL,
    plan_type       VARCHAR(30) DEFAULT '30_day',      -- 30_day, 60_day, custom
    plan_data       JSONB NOT NULL,                    -- structured plan (weeks, days, tasks)
    total_hours     INTEGER,                           -- estimated total study hours
    generated_by    VARCHAR(100),                      -- which LLM model
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_study_plans_user ON study_plans(user_id);

-- =============================================================
-- PEER INTERVIEWS (Matching users for mock interviews)
-- =============================================================
CREATE TABLE peer_interviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interviewer_id  UUID NOT NULL REFERENCES users(id),
    interviewee_id  UUID NOT NULL REFERENCES users(id),
    topic           VARCHAR(100) NOT NULL,
    scheduled_at    TIMESTAMPTZ NOT NULL,
    status          VARCHAR(30) DEFAULT 'scheduled',   -- scheduled, completed, cancelled
    feedback_score  INTEGER,                           -- 1 to 5
    ai_transcript   JSONB,                             -- AI analysis of the voice transcript
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT different_users CHECK (interviewer_id != interviewee_id)
);

CREATE INDEX idx_peer_interviews_users ON peer_interviews(interviewer_id, interviewee_id);

-- =============================================================
-- QUESTS & BOUNTIES (Gamified real-world challenges)
-- =============================================================
CREATE TABLE quests (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    domain          VARCHAR(100) NOT NULL,             -- e.g., 'python', 'architecture'
    difficulty      VARCHAR(50),                       -- easy, medium, hard, epic
    xp_reward       INTEGER DEFAULT 50,
    skill_unlocked  VARCHAR(100),                      -- branch of the skill tree
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_quests (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quest_id        UUID NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    status          VARCHAR(30) DEFAULT 'in_progress', -- in_progress, completed, failed
    completion_data JSONB,                             -- flexible submission details/code execution
    completed_at    TIMESTAMPTZ,
    PRIMARY KEY (user_id, quest_id)
);

-- =============================================================
-- UNIVERSAL NOSQL STORE (Postgres JSONB for dynamic schema)
-- =============================================================
-- Used for adaptive UI layouts, mental/burnout state, and dynamic 
-- gamification objects (skill tree layout) without requiring schema migrations.
CREATE TABLE user_dynamic_state (
    user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    ui_preferences  JSONB DEFAULT '{}',                -- dynamic adaptive layouts per user
    gamification    JSONB DEFAULT '{"xp": 0, "level": 1, "unlocked_nodes": []}', 
    mental_state    JSONB DEFAULT '{"burnout_risk": 0.0, "last_break": null}', 
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- GIN index allows high-performance queries inside the JSONB documents!
CREATE INDEX idx_user_state_gamification ON user_dynamic_state USING GIN (gamification);
