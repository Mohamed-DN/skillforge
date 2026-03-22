# ADR-001: Event-Driven Architecture with Redpanda

## Status
**Accepted** — 2026-03-22

## Context
We need an architecture that:
- Decouples services for independent scaling
- Handles bursty workloads (CV uploads, quiz answers)
- Provides exactly-once event processing
- Supports future on-premise deployment

## Decision
We adopt **Event-Driven Architecture** using **Redpanda** as the event bus:
- Redpanda over Kafka: 10x lower latency, single binary (no JVM/ZK), Kafka-compatible API
- All state changes published as immutable events
- Transactional outbox pattern for exactly-once publishing
- KEDA for auto-scaling consumers based on consumer lag
- Dead-letter queues for failed event processing

## Consequences
### Positive
- Services scale independently
- Natural audit trail via event log
- Easy to add new consumers without modifying producers
- KEDA enables scale-to-zero for cost optimization

### Negative
- Eventual consistency between services (acceptable for our use case)
- Added operational complexity of managing Redpanda cluster
- Need to handle event ordering carefully (partition by user_id)

## References
- DDIA v2, Chapter: Stream Processing
- Kleppmann, "Event Sourcing and Stream Processing" (2016)
