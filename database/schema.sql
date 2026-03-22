-- =============================================================
-- Megaproject Database Schema (Reference)
-- PostgreSQL + pgvector + TimescaleDB
-- =============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";         -- pgvector
CREATE EXTENSION IF NOT EXISTS "timescaledb";    -- TimescaleDB

-- =============================================================
-- USERS
-- =============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    role            VARCHAR(50) DEFAULT 'learner',  -- learner, admin
    career_goal     VARCHAR(255),                    -- e.g., 'backend_engineer', 'fullstack'
    current_role    VARCHAR(255),                    -- e.g., 'frontend_developer'
    experience_years INTEGER DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- =============================================================
-- COMPETENCY VECTORS (pgvector)
-- =============================================================
-- Each user has an embedding representing their skill profile.
-- Updated by AI Workers after each assessment event.
CREATE TABLE competency_vectors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    embedding       vector(1536) NOT NULL,           -- OpenAI-compatible dimensions
    domain          VARCHAR(100) NOT NULL,            -- 'frontend', 'backend', 'system_design', etc.
    confidence      FLOAT DEFAULT 0.0,                -- 0.0 to 1.0
    last_updated_by VARCHAR(255),                     -- event_id that triggered this update
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
    difficulty      VARCHAR(20) DEFAULT 'medium',    -- easy, medium, hard, adaptive
    question_count  INTEGER DEFAULT 10,
    time_limit_sec  INTEGER DEFAULT 600,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE assessment_questions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id   UUID REFERENCES assessments(id) ON DELETE CASCADE,
    question_text   TEXT NOT NULL,
    question_type   VARCHAR(20) NOT NULL,            -- 'mcq', 'open', 'code', 'system_design'
    options         JSONB,                            -- for MCQ: [{"text": "...", "is_correct": true}]
    correct_answer  TEXT,
    domain          VARCHAR(100) NOT NULL,
    difficulty      VARCHAR(20) DEFAULT 'medium',
    is_stealth      BOOLEAN DEFAULT FALSE,           -- stealth question from adjacent domain
    embedding       vector(1536),                     -- for RAG-based question selection
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
    response_time_ms INTEGER,                        -- how fast was the answer
    confidence_score FLOAT,                          -- AI-assessed depth of understanding
    ai_analysis     JSONB,                           -- detailed AI analysis of the answer
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_results_user ON assessment_results(user_id);
CREATE INDEX idx_results_assessment ON assessment_results(assessment_id);

-- =============================================================
-- LEARNING MATERIALS (pgvector for RAG)
-- =============================================================
CREATE TABLE learning_materials (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(500) NOT NULL,
    source          VARCHAR(255),                    -- book title, URL, etc.
    content_chunk   TEXT NOT NULL,                    -- chunked text for RAG
    chunk_index     INTEGER DEFAULT 0,
    domain          VARCHAR(100) NOT NULL,
    tags            TEXT[],
    embedding       vector(1536) NOT NULL,           -- for semantic search
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
    path_data       JSONB NOT NULL,                  -- structured learning path
    generated_by    VARCHAR(255),                    -- which AI model generated it
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
    metric_type     VARCHAR(50) NOT NULL,            -- 'quiz_score', 'response_time', 'streak', 'engagement'
    domain          VARCHAR(100),
    value           FLOAT NOT NULL,
    metadata        JSONB
);

-- Convert to TimescaleDB hypertable for efficient time-series queries
SELECT create_hypertable('user_progress', 'time');

CREATE INDEX idx_progress_user_time ON user_progress(user_id, time DESC);
CREATE INDEX idx_progress_metric ON user_progress(metric_type, time DESC);

-- =============================================================
-- EVENTS OUTBOX (Transactional Outbox Pattern)
-- =============================================================
-- Events are written here in the same transaction as state changes.
-- A separate relay process reads and publishes them to Redpanda.
CREATE TABLE events_outbox (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type      VARCHAR(100) NOT NULL,           -- 'UserAnsweredQuestion', 'CompetencyUpdated', etc.
    aggregate_type  VARCHAR(100) NOT NULL,            -- 'user', 'assessment', etc.
    aggregate_id    UUID NOT NULL,
    payload         JSONB NOT NULL,
    published       BOOLEAN DEFAULT FALSE,
    published_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_outbox_unpublished ON events_outbox(published, created_at)
    WHERE published = FALSE;
