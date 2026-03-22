# Chat Service

Real-time AI conversational interface for SkillForge. Users chat naturally with the AI, which simultaneously teaches, evaluates, and builds their profile.

## How It Works

```
User ←→ WebSocket ←→ Chat Service ←→ LLM Gateway ←→ DeepSeek/Gemini/OpenAI
                          │
                          ▼
                     Redpanda Events
                          │
                          ▼
               User Intelligence Worker
                          │
                          ▼
                   Profile Updated (pgvector)
```

Every message the user sends is also an **implicit assessment**:
- How they phrase technical concepts → reveals depth of understanding
- Response time and language patterns → reveals confidence level
- Topics they ask about → reveals learning interests and gaps
- Code snippets they share → reveals practical skills
- Questions they avoid → reveals knowledge boundaries

## Features
- **WebSocket connections** — Real-time bidirectional chat
- **Conversation sessions** — Persistent chat history per user
- **Context-aware AI** — Injected user profile + learning path into system prompt
- **Multi-turn memory** — Maintains conversation context across messages
- **Streaming responses** — Token-by-token LLM response streaming
- **Chat topics** — Categorized conversations (general, technical, career)
- **Conversation summarization** — Periodic AI summary of long conversations
- **Export** — Users can export their chat history (GDPR)

## Events Produced
| Event | Topic | Purpose |
|-------|-------|---------|
| `ChatMessageSent` | `chat.message.sent` | User sent a message |
| `ChatResponseGenerated` | `chat.response.generated` | AI responded |
| `ChatSessionStarted` | `chat.session.started` | New conversation began |
| `ChatSessionEnded` | `chat.session.ended` | Conversation ended |

## API Endpoints
- `WS /chat/ws` — WebSocket connection for real-time chat
- `POST /chat/sessions` — Create new chat session
- `GET /chat/sessions` — List user's chat sessions
- `GET /chat/sessions/:id/messages` — Get chat history
- `DELETE /chat/sessions/:id` — Delete session (GDPR)
- `GET /chat/sessions/:id/export` — Export session (GDPR)

## Tech
- FastAPI + WebSockets
- Redis (conversation context cache, rate limiting)
- LiteLLM (AI responses via LLM Gateway)
- Redpanda (event publishing)
- SQLAlchemy (chat history storage)

## Running
```bash
cd services/chat-service
pip install -r requirements.txt
uvicorn src.main:app --reload --port 8007
```
