# API Gateway

The public-facing REST/WebSocket API service. Handles authentication, request validation, and event publishing to Redpanda.

## Responsibilities
- JWT authentication (login/register)
- Request validation (Pydantic)
- Route to internal services
- Publish user action events to Redpanda
- Rate limiting

## Tech
- FastAPI + Uvicorn
- Pydantic v2
- python-jose (JWT)
- aiokafka (Redpanda producer)

## Endpoints
- `POST /auth/register` — Register new user
- `POST /auth/login` — Login, returns JWT
- `GET /health` — Health check
- `GET /ready` — Readiness check
- `POST /assessments/start` — Start a quiz session
- `POST /assessments/answer` — Submit an answer (publishes event)
- `GET /profile` — Get current user profile
- `POST /cv/upload` — Upload CV (publishes event)

## Running
```bash
cd services/api-gateway
pip install -r requirements.txt
uvicorn src.main:app --reload --port 8000
```
