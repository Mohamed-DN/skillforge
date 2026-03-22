# LLM Gateway

LiteLLM-based intelligent model router. Routes AI requests to the optimal provider based on task type, cost, and availability.

## Responsibilities
- Route AI tasks to DeepSeek, Gemini, or OpenAI
- Fallback logic if primary provider is down
- Cost tracking and token usage logging
- Rate limiting per provider
- Future: route to on-premise vLLM

## Model Routing Strategy

| Task Type | Primary | Fallback | Reason |
|-----------|---------|----------|--------|
| Quiz generation | DeepSeek | OpenAI | Fast, cheap, structured output |
| CV analysis | Gemini | OpenAI | Long context (1M+ tokens) |
| Skill reasoning | OpenAI | Gemini | Strong general reasoning |
| Code evaluation | DeepSeek | OpenAI | Code specialization |

## Running
```bash
cd services/llm-gateway
pip install -r requirements.txt
uvicorn src.main:app --reload --port 8001
```
