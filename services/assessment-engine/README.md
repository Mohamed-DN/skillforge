# Assessment Engine

Generates adaptive quizzes using RAG (Retrieval Augmented Generation) and evaluates user answers.

## Responsibilities
- Generate personalized quiz questions via RAG
- Inject "stealth" questions from adjacent domains (15%)
- Evaluate answers and compute scores
- Adapt difficulty based on competency vector

## Running
```bash
cd services/assessment-engine
pip install -r requirements.txt
uvicorn src.main:app --reload --port 8002
```
