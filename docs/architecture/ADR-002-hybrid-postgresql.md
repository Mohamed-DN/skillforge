# ADR-002: Hybrid PostgreSQL (pgvector + TimescaleDB)

## Status
**Accepted** — 2026-03-22

## Context
We need a database that supports:
- Traditional relational data (users, assessments)
- Vector embeddings for RAG semantic search (competency vectors, learning materials)
- Time-series analytics (user progress tracking over time)

Options considered:
1. PostgreSQL + separate Pinecone/Weaviate for vectors + separate InfluxDB for time-series
2. PostgreSQL + pgvector + TimescaleDB (single engine, multiple extensions)

## Decision
Use **PostgreSQL with pgvector and TimescaleDB extensions** as a single unified database:
- **pgvector**: Vector similarity search (cosine, L2, inner product) with IVFFlat indexing
- **TimescaleDB**: Hypertables for time-series data with automatic partitioning and compression
- **Standard PostgreSQL**: Relational tables with full ACID transactions

## Consequences
### Positive
- Single database to operate, backup, and monitor
- Transactional consistency across relational + vector data
- TimescaleDB hypertables auto-partition time-series data
- Simpler infrastructure (no separate vector DB or time-series DB)
- Outbox pattern works within same transaction boundary

### Negative
- pgvector performance may not match dedicated vector databases at extreme scale (>10M vectors)
- TimescaleDB adds memory overhead
- Must carefully tune IVFFlat index parameters as data grows

## References
- DDIA v2, Chapter: Storage and Retrieval
- TimescaleDB documentation on pgvector integration
