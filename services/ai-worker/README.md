# AI Worker

Event-driven worker that consumes events from Redpanda, processes them with the LLM Gateway, and updates the database.

## Responsibilities
- Consume events from Redpanda topics
- Call LLM Gateway for AI analysis
- Update competency vectors in pgvector
- Produce derived events (CompetencyVectorUpdated)
- Dead-letter queue for failed processing
- Idempotent processing (event_id deduplication)

## Events Consumed
- `UserAnsweredQuestion` — Analyze answer depth and update skills
- `CVUploaded` — Trigger CV analysis pipeline

## Events Produced
- `CompetencyVectorUpdated` — After skill recalculation
- `LearningPathGenerated` — After path update

## Running
```bash
cd services/ai-worker
pip install -r requirements.txt
python -m src.main
```
