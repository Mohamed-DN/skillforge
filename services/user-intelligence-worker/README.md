# User Intelligence Worker

Event-driven worker that analyzes user conversations and interactions to automatically extract insights, detect skills, and continuously update the user's competency profile.

## The Intelligence Pipeline

```
Chat Messages ──┐
Quiz Answers ───┤
CV Analysis ────┤──→ User Intelligence Worker ──→ Updated User Profile
Login Patterns ─┤                                    │
Session Data ───┘                                    ▼
                                              competency_vectors (pgvector)
                                              user_insights (JSONB)
                                              communication_profile
```

## What It Extracts

### From Chat Conversations
| Signal | What It Reveals | Example |
|--------|----------------|---------|
| **Vocabulary** | Technical depth | "This is O(n log n)" → knows algo complexity |
| **Question patterns** | Knowledge gaps | "What's the difference between TCP and UDP?" → networking beginner |
| **Code sharing** | Practical skills | Shares Python → Python proficiency |
| **Self-corrections** | Learning speed | "Wait, actually..." → reflective learner |
| **Topic switches** | Interest areas | Keeps asking about K8s → strong interest |
| **Confidence language** | Self-awareness | "I think..." vs "I know..." |
| **Response depth** | Understanding level | Short vs detailed explanations |
| **Language style** | Communication maturity | Structured vs unstructured responses |

### From All Interactions (Cross-Service)
| Source | Insight |
|--------|---------|
| Quiz answers | Speed, accuracy, difficulty mapping |
| Chat messages | Communication style, technical vocabulary depth |
| CV data | Established skills, experience timeline |
| Login patterns | Engagement level, preferred study times |
| Session duration | Focus capacity, learning stamina |
| Feature usage | Learning preferences (quiz vs chat vs reading) |

## How It Works (DDIA Ch12 — Stream Processing)

1. **Consume events** from Redpanda topics:
   - `chat.message.sent` — every user chat message
   - `assessment.answer` — every quiz answer
   - `cv.analyzed` — CV analysis results
   - `user.session.*` — login/logout/activity events

2. **Batch analysis** — Groups recent messages into windows (5-10 messages)

3. **AI extraction** — Sends batched messages to LLM with structured prompt:
   ```
   Analyze these messages from user X. Extract:
   - Technical skills mentioned or demonstrated (with confidence 0-1)
   - Knowledge gaps detected
   - Communication style traits
   - Learning interests
   - Suggested competency vector updates
   Output as JSON.
   ```

4. **Vector update** — Incrementally adjusts the user's competency vector:
   ```python
   # Weighted moving average — new insights blend with existing profile
   new_vector = (0.8 * current_vector) + (0.2 * extracted_insights_vector)
   ```

5. **Profile enrichment** — Updates `user_insights` table with structured data

## Events Consumed
| Event | Action |
|-------|--------|
| `ChatMessageSent` | Buffer → batch analyze when 5+ messages |
| `AssessmentAnswered` | Update skill confidence scores |
| `CVAnalyzed` | Initialize/update skills from CV |
| `UserLoggedIn` | Track engagement patterns |
| `UserSessionEnded` | Calculate session metrics |

## Events Produced
| Event | Trigger |
|-------|---------|
| `UserProfileEnriched` | After successful analysis |
| `SkillGapDetected` | New gap found in conversation |
| `LearningStyleUpdated` | Communication pattern changed |
| `CompetencyVectorUpdated` | Vector adjustment applied |

## Privacy & GDPR (DDIA Ch14)
- All analysis is **opt-in** (user must consent to conversation analysis)
- Users can **view** all extracted insights (`GET /profile/insights`)
- Users can **delete** all analysis data (`DELETE /gdpr/erase`)
- Raw chat messages are **never** stored longer than retention period
- Analysis results are **anonymizable** (can strip PII on request)
- **No data** is shared with third parties

## Tech
- Python consumer (confluent-kafka)
- LiteLLM (analysis via LLM Gateway)
- SQLAlchemy (profile writes)
- pgvector (competency vector updates)
- Redis (message buffering, deduplication)

## Running
```bash
cd services/user-intelligence-worker
pip install -r requirements.txt
python -m src.main
```
