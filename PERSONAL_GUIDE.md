# 📖 SkillForge — La Tua Guida Personale (Zero → Produzione)

> Questa guida è scritta **solo per te, Mohamed**. Spiega tutto il progetto da zero,
> come costruire ogni pezzo a mano, e cosa imparerai ad ogni passo.
> Il progetto ha **12 microservizi**, **22 tabelle**, **25 tipi di evento**.

---

## 🧠 Cos'è SkillForge in 30 Secondi

Un'app dove:
1. L'utente si registra, paga (Free/Pro/Enterprise) e carica il CV
2. L'IA legge il CV e capisce le competenze attuali
3. L'utente chatta con l'IA — e l'IA **analizza come parla** per capire il suo livello
4. Ogni giorno l'utente fa quiz adattivi con "domande stealth" da domini adiacenti
5. L'IA incrocia chat + quiz + CV + comportamento → aggiorna il profilo in tempo reale
6. Il percorso di apprendimento si adatta continuamente — l'utente cresce senza accorgersene

**Scalabile da 100 a 100.000 utenti** grazie a Kubernetes + KEDA (auto-scaling).

---

## 🏗️ I Componenti del Sistema (11 microservizi)

| # | Servizio | Tipo | Porta | Cosa Fa |
|---|----------|------|-------|---------|
| 1 | **api-gateway** | HTTP | 8000 | Porta d'ingresso: riceve richieste, valida JWT, pubblica eventi |
| 2 | **auth-service** | HTTP | 8005 | Login, registrazione, JWT RS256, bcrypt, MFA, GDPR |
| 3 | **billing-service** | HTTP | 8006 | Stripe, abbonamenti, fatture, webhook pagamenti |
| 4 | **chat-service** | WebSocket | 8007 | Chat in tempo reale con l'IA, streaming risposte |
| 5 | **llm-gateway** | HTTP | 8001 | Router intelligente: smista richieste a DeepSeek/Gemini/OpenAI |
| 6 | **ai-worker** | Worker | — | Consuma eventi, analizza risposte quiz, aggiorna vettori |
| 7 | **user-intelligence-worker** | Worker | — | Analizza chat/quiz/CV/comportamento → arricchisce profilo |
| 8 | **assessment-engine** | HTTP | 8002 | Genera quiz personalizzati con RAG (pgvector) |
| 9 | **career-advisor-service** | HTTP | 8008 | Analizza offerte lavoro, genera plan di studio (Skill Gap) |
| 10 | **user-profile-service** | HTTP | 8003 | CRUD profilo, vettori competenze, obiettivi |
| 11 | **cv-analyzer** | Worker | — | Parsing CV (PDF/DOCX), estrazione skills |
| 12 | **notification-service** | HTTP | 8004 | Email, push, in-app notifications |

### I 3 Tipi di Servizio
- **HTTP** = API che risponde a richieste (FastAPI + Uvicorn)
- **WebSocket** = Connessione bidirezionale in tempo reale (FastAPI + WebSockets)
- **Worker** = Loop infinito che consuma eventi da Redpanda (nessuna porta)

---

## 🔧 PASSO 0: Prepara il Tuo Mac

Prima di tutto, installa tutti gli strumenti necessari.

```bash
# 1. Installa Homebrew (il package manager di macOS)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Installa tutti gli strumenti
brew install python@3.12 podman podman-compose kubectl helm minikube git

# 3. Inizializza Podman (crea la VM Linux per i container)
podman machine init --cpus=4 --memory=8192
podman machine start

# 4. Verifica che tutto funzioni
podman --version        # Container engine (sostituto di Docker)
python3.12 --version    # Linguaggio di programmazione
kubectl version --client # Kubernetes CLI
helm version            # Package manager per K8s
minikube version        # Cluster K8s locale

# 5. Clona il tuo repo
git clone https://github.com/Mohamed-DN/skillforge.git
cd skillforge

# 6. Copia il file .env
cp .env.example .env
# → Apri .env e inserisci le tue chiavi API (DeepSeek, OpenAI, Google, Stripe)
```

**✅ Checkpoint**: Tutti i comandi restituiscono una versione? Hai clonato il repo? Vai avanti.

---

## 🔧 PASSO 1: Database (DDIA Cap. 3-4)

> **Cosa impari**: Come si salvano i dati, cos'è un indice, come funziona la ricerca vettoriale.

### 1.1 Avvia PostgreSQL

```bash
# Avvia SOLO il database (non tutto lo stack)
podman-compose -f infra/containers/podman-compose.yml up -d postgres

# Aspetta che sia pronto (deve dire "healthy")
podman ps

# Connettiti al database
podman exec -it skillforge-postgres psql -U skillforge -d skillforge
```

### 1.2 Crea lo Schema

```sql
-- Dentro psql, esegui lo schema completo:
\i /docker-entrypoint-initdb.d/01-schema.sql

-- Verifica le tabelle create (dovrebbero essere 19):
\dt

-- Verifica le estensioni:
\dx
-- Devi vedere: uuid-ossp, vector, timescaledb, pgcrypto
```

### 1.3 Testa a Mano

```sql
-- Inserisci un utente di test
INSERT INTO users (email, full_name, role, career_goal)
VALUES ('mohamed@test.com', 'Mohamed', 'admin', 'Senior Engineer');

-- Verifica
SELECT * FROM users;

-- Inserisci un vettore di competenza (simulato, 3 dimensioni per test)
-- In produzione saranno 1536 dimensioni
INSERT INTO competency_vectors (user_id, embedding, domain, confidence)
VALUES (
  (SELECT id FROM users WHERE email='mohamed@test.com'),
  '[0.1, 0.8, 0.3]'::vector(3),
  'python',
  0.8
);

-- Ricerca per similarità (il cuore di RAG!)
SELECT domain, confidence FROM competency_vectors
ORDER BY embedding <=> '[0.2, 0.7, 0.4]'::vector(3)
LIMIT 5;

-- Inserisci un record nell'audit log (immutabile, GDPR!)
INSERT INTO audit_log (actor_id, actor_type, action, resource_type, details)
VALUES (
  (SELECT id FROM users WHERE email='mohamed@test.com'),
  'user', 'login', 'session',
  '{"ip": "192.168.1.1", "browser": "Chrome"}'::jsonb
);

-- Esci
\q
```

**✅ Checkpoint**: Riesci a inserire un utente, un vettore, e fare una ricerca per similarità? Perfetto.

**📚 Libro**: Rileggi DDIA Cap. 3 (Data Models), Cap. 4 (Storage & Retrieval — B-tree, LSM-tree, indexes).

---

## 🔧 PASSO 2: Auth Service — La Sicurezza (DDIA Cap. 8, 10)

> **Cosa impari**: bcrypt, JWT RS256, RBAC, transazioni ACID.

### 2.1 Crea il Progetto

```bash
cd services/auth-service

# Crea virtual environment (ambiente Python isolato)
python3.12 -m venv .venv
source .venv/bin/activate

# Installa le dipendenze
pip install fastapi uvicorn sqlalchemy asyncpg pydantic \
  python-jose[cryptography] passlib[bcrypt] redis pyotp
pip freeze > requirements.txt
```

### 2.2 Genera le Chiavi RSA (per JWT)

```bash
# Crea la directory delle chiavi
mkdir -p keys

# Genera la coppia di chiavi RSA (2048 bit)
openssl genrsa -out keys/private.pem 2048
openssl rsa -in keys/private.pem -pubout -out keys/public.pem

# La chiave privata FIRMA i token (solo auth-service la ha)
# La chiave pubblica VERIFICA i token (tutti i servizi la hanno)
```

### 2.3 Scrivi il Codice

Crea `src/main.py`:

```python
from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
import os

app = FastAPI(title="SkillForge Auth Service")

# === Configurazione ===
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
PRIVATE_KEY = open("keys/private.pem").read()
PUBLIC_KEY = open("keys/public.pem").read()
ALGORITHM = "RS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# === Modelli ===
class RegisterRequest(BaseModel):
    email: str
    password: str
    full_name: str

class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# === Funzioni Core ===
def hash_password(password: str) -> str:
    """bcrypt: trasforma "password123" → "$2b$12$LJ3m4ys3..." (irreversibile)"""
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    """Confronta password inserita con hash salvato"""
    return pwd_context.verify(plain, hashed)

def create_access_token(user_id: str, role: str) -> str:
    """Crea JWT firmato con chiave privata RS256"""
    payload = {
        "sub": user_id,                          # Subject: chi è
        "role": role,                            # Ruolo: admin/learner/premium
        "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
        "iat": datetime.utcnow(),                # Issued At: quando è stato creato
    }
    return jwt.encode(payload, PRIVATE_KEY, algorithm=ALGORITHM)

# === Endpoints ===
@app.post("/auth/register", response_model=TokenResponse)
async def register(req: RegisterRequest):
    # 1. Hash della password (MAI salvare in chiaro!)
    password_hash = hash_password(req.password)
    # 2. Salva nel DB (qui semplificato, in produzione usa SQLAlchemy)
    # db.save(user_id, req.email, password_hash)
    # 3. Genera token
    token = create_access_token(user_id="uuid-here", role="learner")
    return TokenResponse(access_token=token)

@app.post("/auth/login", response_model=TokenResponse)
async def login(req: LoginRequest):
    # 1. Cerca utente nel DB
    # user = db.find_by_email(req.email)
    # 2. Verifica password con bcrypt
    # if not verify_password(req.password, user.password_hash):
    #     raise HTTPException(401, "Invalid credentials")
    # 3. Genera token
    token = create_access_token(user_id="uuid-here", role="learner")
    return TokenResponse(access_token=token)

@app.get("/auth/me")
async def get_me():
    """Restituisce info dell'utente dal JWT"""
    return {"message": "Implement JWT validation middleware"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth-service"}
```

### 2.4 Avvia e Testa

```bash
# Avvia
uvicorn src.main:app --reload --port 8005

# Apri http://localhost:8005/docs
# → Vedrai Swagger UI con tutti gli endpoint
# → Prova POST /auth/register con un JSON

# Testa con curl:
curl -X POST http://localhost:8005/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "mohamed@test.com", "password": "MyS3cur3!", "full_name": "Mohamed"}'

# Riceverai un JWT token. Copialo e decodificalo su https://jwt.io
# Vedrai i campi: sub (user_id), role, exp, iat
```

**✅ Checkpoint**: Riesci a registrarti e ricevere un JWT? Riesci a decodificarlo su jwt.io?

**📚 Libro**: DDIA Cap. 8 (Transactions — ACID), Cap. 10 (Consistency — strong vs eventual).

---

## 🔧 PASSO 3: API Gateway (DDIA Cap. 2)

> **Cosa impari**: Come costruire un'API pubblica, validazione, middleware, SLO.

### 3.1 Crea il Progetto

```bash
cd services/api-gateway
python3.12 -m venv .venv && source .venv/bin/activate
pip install fastapi uvicorn pydantic python-jose[cryptography] httpx confluent-kafka
pip freeze > requirements.txt
```

### 3.2 Scrivi il Codice

Crea `src/main.py`:

```python
from fastapi import FastAPI, Depends, HTTPException, Header
from jose import jwt, JWTError
import httpx

app = FastAPI(title="SkillForge API Gateway", version="1.0.0")

# Chiave pubblica dell'auth-service (per verificare i JWT)
PUBLIC_KEY = open("../auth-service/keys/public.pem").read()

# === JWT Middleware ===
async def verify_token(authorization: str = Header(...)):
    """Verifica che il JWT sia valido (firmato con la chiave giusta, non scaduto)"""
    try:
        token = authorization.replace("Bearer ", "")
        payload = jwt.decode(token, PUBLIC_KEY, algorithms=["RS256"])
        return payload  # Contiene: sub (user_id), role, exp
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

# === Endpoints Pubblici ===
@app.get("/health")
async def health():
    return {"status": "ok", "service": "api-gateway"}

# === Endpoints Protetti (richiedono JWT) ===
@app.get("/api/v1/profile")
async def get_profile(user=Depends(verify_token)):
    """Esempio di endpoint protetto — solo utenti autenticati"""
    return {"user_id": user["sub"], "role": user["role"]}

@app.post("/api/v1/quiz/answer")
async def submit_answer(user=Depends(verify_token)):
    """Riceve risposta quiz → pubblica evento su Redpanda"""
    # 1. Valida la risposta con Pydantic
    # 2. Pubblica evento "UserAnsweredQuestion" su Redpanda
    # 3. Ritorna conferma
    return {"status": "answer_received", "event_published": True}

@app.post("/api/v1/cv/upload")
async def upload_cv(user=Depends(verify_token)):
    """Riceve CV → salva su MinIO → pubblica evento"""
    return {"status": "cv_uploaded", "event_published": True}
```

### 3.3 Avvia e Testa

```bash
uvicorn src.main:app --reload --port 8000

# Prima registrati sull'auth-service e ottieni un token
TOKEN="eyJ..."  # il token che hai preso dal passo 2

# Poi chiama l'API Gateway con il token
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/profile
```

**✅ Checkpoint**: L'API rifiuta richieste senza token? Accetta con token valido? Perfetto.

---

## 🔧 PASSO 4: Redpanda — Event Bus (DDIA Cap. 5, 12)

> **Cosa impari**: Event sourcing, producer/consumer, topic partitioning, immutabilità.

### 4.1 Avvia Redpanda

```bash
# Avvia Redpanda + Console UI
podman-compose -f infra/containers/podman-compose.yml up -d redpanda redpanda-console

# Verifica
podman ps  # Deve mostrare redpanda e redpanda-console attivi
```

### 4.2 Crea i Topic

```bash
# Entra nel container
podman exec -it skillforge-redpanda /bin/bash

# Crea i topic (partizionati per user_id — DDIA Cap. 7 Sharding)
rpk topic create user.registered --partitions 6
rpk topic create assessment.answer --partitions 12
rpk topic create assessment.completed --partitions 6
rpk topic create cv.uploaded --partitions 6
rpk topic create cv.analyzed --partitions 6
rpk topic create chat.message.sent --partitions 12
rpk topic create chat.response.generated --partitions 6
rpk topic create user.profile.enriched --partitions 6
rpk topic create skill.gap.detected --partitions 6
rpk topic create competency.vector.updated --partitions 6
rpk topic create learning.path.generated --partitions 6
rpk topic create subscription.created --partitions 3
rpk topic create payment.succeeded --partitions 3
rpk topic create payment.failed --partitions 3
rpk topic create dead-letter --partitions 3

# Verifica
rpk topic list

# Esci
exit
```

### 4.3 Apri la Console

Apri **http://localhost:8080** nel browser → vedrai tutti i topic, messaggi, consumer groups.

### 4.4 Testa Producer/Consumer (Python)

```python
# test_events.py — esegui nella root del progetto
from confluent_kafka import Producer, Consumer
import json, uuid

# === PRODUCER: pubblica un evento ===
producer = Producer({'bootstrap.servers': 'localhost:9092'})

event = {
    "event_id": str(uuid.uuid4()),
    "event_type": "UserAnsweredQuestion",
    "user_id": "user-123",
    "question_id": "q-456",
    "is_correct": True,
    "response_time_ms": 3200,
    "domain": "python",
}

producer.produce('assessment.answer', key="user-123", value=json.dumps(event))
producer.flush()
print(f"✅ Evento pubblicato: {event['event_type']}")

# === CONSUMER: leggi l'evento ===
consumer = Consumer({
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'test-consumer',
    'auto.offset.reset': 'earliest',
})
consumer.subscribe(['assessment.answer'])

msg = consumer.poll(timeout=5.0)
if msg:
    data = json.loads(msg.value())
    print(f"✅ Evento ricevuto: {data['event_type']} — user={data['user_id']}")
consumer.close()
```

```bash
pip install confluent-kafka
python test_events.py
# Deve stampare: "Evento pubblicato" + "Evento ricevuto"
```

**✅ Checkpoint**: Vedi l'evento nella Console Redpanda (http://localhost:8080)? Perfetto.

**📚 Libro**: DDIA Cap. 5 (Encoding — Protobuf vs JSON), Cap. 12 (Stream Processing).

---

## 🔧 PASSO 5: LLM Gateway (DDIA Cap. 1 — Trade-offs)

> **Cosa impari**: Abstraction layer, fallback, cost optimization.

### 5.1 Crea il Progetto

```bash
cd services/llm-gateway
python3.12 -m venv .venv && source .venv/bin/activate
pip install fastapi uvicorn litellm pydantic
pip freeze > requirements.txt
```

### 5.2 Scrivi il Codice

```python
# src/main.py
from fastapi import FastAPI
from pydantic import BaseModel
import litellm

app = FastAPI(title="SkillForge LLM Gateway")

class CompletionRequest(BaseModel):
    task_type: str      # "quiz", "cv_analysis", "chat", "skill_extraction"
    messages: list
    max_tokens: int = 1000

# Routing basato sul tipo di task (trade-off costo/qualità)
MODEL_ROUTING = {
    "quiz":             "deepseek/deepseek-chat",       # Veloce ed economico
    "chat":             "deepseek/deepseek-chat",       # Conversazionale
    "cv_analysis":      "gemini/gemini-2.0-flash",      # Contesto lungo
    "skill_extraction": "deepseek/deepseek-chat",       # Strutturato
    "code_review":      "openai/gpt-4o-mini",           # Precisione
}

FALLBACK_MODEL = "openai/gpt-4o-mini"  # Se il primario fallisce

@app.post("/llm/complete")
async def complete(req: CompletionRequest):
    model = MODEL_ROUTING.get(req.task_type, FALLBACK_MODEL)
    try:
        response = litellm.completion(
            model=model,
            messages=req.messages,
            max_tokens=req.max_tokens,
        )
        return {
            "content": response.choices[0].message.content,
            "model": model,
            "tokens_used": response.usage.total_tokens,
            "cost": response._hidden_params.get("response_cost", 0),
        }
    except Exception as e:
        # FALLBACK: se il modello primario fallisce, prova il backup
        response = litellm.completion(
            model=FALLBACK_MODEL,
            messages=req.messages,
            max_tokens=req.max_tokens,
        )
        return {
            "content": response.choices[0].message.content,
            "model": FALLBACK_MODEL,
            "fallback": True,
            "original_error": str(e),
        }
```

```bash
# Avvia
uvicorn src.main:app --reload --port 8001

# Testa
curl -X POST http://localhost:8001/llm/complete \
  -H "Content-Type: application/json" \
  -d '{"task_type": "quiz", "messages": [{"role": "user", "content": "Genera 3 domande su Python"}]}'
```

**✅ Checkpoint**: Ricevi una risposta dall'LLM? Il routing funziona? Perfetto.

---

## 🔧 PASSO 6: AI Worker (DDIA Cap. 12-13 — Stream Processing)

> **Cosa impari**: Consumer groups, idempotenza, dead-letter queue, event loop.

```python
# services/ai-worker/src/main.py
from confluent_kafka import Consumer, Producer
import json, httpx, uuid

# === Config ===
consumer = Consumer({
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'ai-worker-group',      # Consumer Group = distribuzione del lavoro
    'auto.offset.reset': 'earliest',
    'enable.auto.commit': False,         # Commit manuale = exactly-once
})
consumer.subscribe(['assessment.answer', 'cv.analyzed'])

producer = Producer({'bootstrap.servers': 'localhost:9092'})
LLM_URL = "http://localhost:8001/llm/complete"
processed_ids = set()  # Deduplicazione idempotente

def process_event(event: dict):
    """Elabora un singolo evento"""
    event_id = event.get("event_id")

    # IDEMPOTENZA: se l'ho già processato, salto (DDIA Cap. 12)
    if event_id in processed_ids:
        print(f"⏭️  Evento già processato: {event_id}")
        return

    event_type = event.get("event_type")

    if event_type == "UserAnsweredQuestion":
        # Chiedi all'LLM di analizzare la risposta
        response = httpx.post(LLM_URL, json={
            "task_type": "skill_extraction",
            "messages": [{
                "role": "user",
                "content": f"Analizza questa risposta quiz. Dominio: {event['domain']}. "
                           f"Corretta: {event['is_correct']}. "
                           f"Tempo risposta: {event['response_time_ms']}ms. "
                           f"Estrai il livello di competenza (0.0-1.0) come JSON."
            }]
        })
        analysis = response.json()
        # → Qui aggiorneresti il competency_vector nel DB (pgvector)
        print(f"✅ Analizzato: user={event['user_id']}, dominio={event['domain']}")

        # Pubblica evento di aggiornamento
        update_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "CompetencyVectorUpdated",
            "user_id": event["user_id"],
            "domain": event["domain"],
            "triggered_by_event_id": event_id,
        }
        producer.produce('competency.vector.updated',
                         key=event["user_id"],
                         value=json.dumps(update_event))
        producer.flush()

    processed_ids.add(event_id)

# === Main Loop ===
print("🚀 AI Worker avviato — in ascolto...")
while True:
    msg = consumer.poll(timeout=1.0)
    if msg is None:
        continue
    if msg.error():
        # Manda alla Dead Letter Queue
        producer.produce('dead-letter', value=msg.value())
        producer.flush()
        continue

    try:
        event = json.loads(msg.value())
        process_event(event)
        consumer.commit(msg)  # Commit DOPO il processing (at-least-once)
    except Exception as e:
        print(f"❌ Errore: {e} — evento mandato alla DLQ")
        producer.produce('dead-letter', value=msg.value())
        producer.flush()
        consumer.commit(msg)
```

```bash
# In un terminale: avvia il worker
cd services/ai-worker && python -m src.main

# In un altro terminale: pubblica un evento di test
python test_events.py
# → Il worker lo elaborerà e stamperà "Analizzato: ..."
```

**✅ Checkpoint**: Il worker consuma l'evento, chiama l'LLM, e pubblica un nuovo evento? Perfetto.

**📚 Libro**: DDIA Cap. 12 (Stream Processing — exactly-once, consumer groups), Cap. 13 (Philosophy — derived data).

---

## 🔧 PASSO 7: Chat Service (WebSocket + Intelligence)

> **Cosa impari**: WebSocket, streaming AI, analisi passiva delle conversazioni.

```python
# services/chat-service/src/main.py
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from confluent_kafka import Producer
import litellm, json, uuid
from datetime import datetime

app = FastAPI(title="SkillForge Chat Service")
producer = Producer({'bootstrap.servers': 'localhost:9092'})

@app.websocket("/chat/ws")
async def chat_websocket(websocket: WebSocket):
    await websocket.accept()
    session_id = str(uuid.uuid4())
    user_id = "user-from-jwt"  # In produzione: estratto dal JWT
    history = []

    # Pubblica evento sessione iniziata
    producer.produce('chat.session.started', json.dumps({
        "event_id": str(uuid.uuid4()),
        "event_type": "ChatSessionStarted",
        "user_id": user_id, "session_id": session_id,
    }))
    producer.flush()

    try:
        while True:
            # 1. Ricevi messaggio dall'utente
            user_message = await websocket.receive_text()
            history.append({"role": "user", "content": user_message})

            # 2. Pubblica evento (l'Intelligence Worker lo analizzerà!)
            producer.produce('chat.message.sent', json.dumps({
                "event_id": str(uuid.uuid4()),
                "event_type": "ChatMessageSent",
                "user_id": user_id, "session_id": session_id,
                "content": user_message,
                "token_count": len(user_message.split()),
            }))
            producer.flush()

            # 3. Chiama l'LLM (risposta in streaming)
            response = litellm.completion(
                model="deepseek/deepseek-chat",
                messages=[
                    {"role": "system", "content":
                        "Sei un tutor AI di SkillForge. Aiuta l'utente a imparare. "
                        "Analizza il suo livello dalle domande che fa."},
                    *history
                ],
            )

            ai_reply = response.choices[0].message.content
            history.append({"role": "assistant", "content": ai_reply})

            # 4. Invia risposta all'utente
            await websocket.send_text(ai_reply)

    except WebSocketDisconnect:
        # Pubblica evento sessione terminata
        producer.produce('chat.session.ended', json.dumps({
            "event_id": str(uuid.uuid4()),
            "event_type": "ChatSessionEnded",
            "user_id": user_id, "session_id": session_id,
            "total_messages": len(history),
        }))
        producer.flush()
```

**✅ Checkpoint**: Riesci a chattare via WebSocket e vedi gli eventi nel topic `chat.message.sent`?

---

## 🔧 PASSO 8: User Intelligence Worker (Il Cervello Segreto)

> **Cosa impari**: Analisi comportamentale, weighted moving average, profiling passivo.

```python
# services/user-intelligence-worker/src/main.py
from confluent_kafka import Consumer, Producer
import json, httpx, uuid

consumer = Consumer({
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'user-intelligence-group',
    'auto.offset.reset': 'earliest',
    'enable.auto.commit': False,
})
consumer.subscribe(['chat.message.sent', 'assessment.answer', 'cv.analyzed'])

producer = Producer({'bootstrap.servers': 'localhost:9092'})
LLM_URL = "http://localhost:8001/llm/complete"

# Buffer per batch analysis (accumula 5 messaggi, poi analizza)
message_buffer = {}  # user_id → [messages]

def analyze_batch(user_id: str, messages: list):
    """Analizza un batch di messaggi con l'LLM e aggiorna il profilo"""
    combined = "\n".join([f"- {m['content']}" for m in messages])

    response = httpx.post(LLM_URL, json={
        "task_type": "skill_extraction",
        "messages": [{
            "role": "user",
            "content": f"""Analizza questi messaggi dell'utente. Estrai in JSON:
{{
  "skills_detected": [{{"name": "...", "confidence": 0.0-1.0}}],
  "knowledge_gaps": ["..."],
  "communication_style": "concise|detailed|questioning",
  "vocabulary_level": "beginner|intermediate|advanced|expert",
  "technical_density": 0.0-1.0,
  "interests": ["..."],
  "confidence_level": "uncertain|moderate|confident"
}}

Messaggi:
{combined}"""
        }]
    })

    insights = response.json()
    print(f"🧠 Profilo arricchito per {user_id}: {insights.get('content', '')[:100]}...")

    # Pubblica evento
    producer.produce('user.profile.enriched', json.dumps({
        "event_id": str(uuid.uuid4()),
        "event_type": "UserProfileEnriched",
        "user_id": user_id,
        "insight_type": "batch_analysis",
        "source": "chat",
    }))
    producer.flush()

print("🧠 User Intelligence Worker avviato...")
while True:
    msg = consumer.poll(timeout=1.0)
    if msg is None:
        continue
    if msg.error():
        continue

    event = json.loads(msg.value())
    user_id = event.get("user_id", "unknown")

    # Accumula nel buffer
    if user_id not in message_buffer:
        message_buffer[user_id] = []
    message_buffer[user_id].append(event)

    # Quando raggiungiamo 5 messaggi, analizziamo il batch
    if len(message_buffer[user_id]) >= 5:
        analyze_batch(user_id, message_buffer[user_id])
        message_buffer[user_id] = []  # Reset buffer

    consumer.commit(msg)
```

**✅ Checkpoint**: Dopo 5 messaggi chat, il worker analizza il batch e pubblica `UserProfileEnriched`?

---

## 🔧 PASSO 9: Assessment Engine + RAG (DDIA Cap. 4)

> **Cosa impari**: Retrieval-Augmented Generation, ricerca vettoriale, quiz personalizzati.

```python
# services/assessment-engine/src/main.py — endpoint chiave
@app.post("/api/v1/quiz/generate")
async def generate_quiz(user=Depends(verify_token)):
    user_id = user["sub"]

    # 1. RETRIEVE: Prendi il vettore competenze dell'utente
    #    e trova materiale didattico simile (pgvector)
    similar_materials = db.execute("""
        SELECT content_chunk, domain FROM learning_materials
        ORDER BY embedding <=> (
            SELECT embedding FROM competency_vectors
            WHERE user_id = %s LIMIT 1
        )
        LIMIT 5
    """, [user_id])

    # 2. AUGMENT: Costruisci il prompt con il materiale trovato
    context = "\n".join([m.content_chunk for m in similar_materials])
    prompt = f"""Basandoti su questo materiale:
{context}

Genera 10 domande quiz. 8 domande sul dominio dell'utente,
2 domande "stealth" da un dominio adiacente (per scoprire talenti nascosti).
Formato JSON: [{{"question": "...", "options": [...], "correct": 0, "domain": "...", "is_stealth": false}}]"""

    # 3. GENERATE: L'LLM genera le domande personalizzate
    response = httpx.post(LLM_URL, json={
        "task_type": "quiz",
        "messages": [{"role": "user", "content": prompt}]
    })

    return {"quiz": response.json()["content"]}
```

---

## 🔧 PASSO 10: Billing con Stripe (DDIA Cap. 8 — ACID)

> **Cosa impari**: Pagamenti sicuri, webhook, transazioni ACID per soldi reali.

```bash
# 1. Crea account su https://dashboard.stripe.com
# 2. Prendi le chiavi API (test mode!)
# 3. Installa Stripe CLI per testare webhook
brew install stripe/stripe-cli/stripe
stripe login
stripe listen --forward-to localhost:8006/billing/webhooks/stripe
```

**Regola d'oro**: MAI toccare i dati delle carte. Stripe li gestisce lui (PCI compliance).

---

## 🔧 PASSO 11: CV Analyzer + Notification Service

> **Cosa impari**: File processing asincrono, MinIO/S3, notifiche push.

```bash
# Avvia MinIO (object storage per i CV)
podman-compose -f infra/containers/podman-compose.yml up -d minio

# Console MinIO: http://localhost:9001
# Login: skillforge / skillforge_minio_CHANGE_ME
```

---

## 🔧 PASSO 12: Career Advisor & The Brilliance Tier (DDIA Cap. 13)

> **Cosa impari**: JsonB NoSQL flexibility inside Postgres, gamification loops, Job Market analysis.

```python
# services/career-advisor-service/src/main.py (Esempio)
@app.post("/api/v1/career/analyze")
async def analyze_job_offer(job_text: str, user=Depends(verify_token)):
    # 1. Estrarre le skill dall'offerta (LLM)
    # 2. Fare una vector search contro il competency_vector dell'utente
    # 3. Restituire il GAP: cosa non sa fare
    return {"gaps": ["Kubernetes", "Redis"]}

# La genialità del NoSQL (JSONB) dentro Postgres (schema.sql)
# CREATE TABLE user_dynamic_state (
#    user_id UUID,
#    ui_preferences JSONB,     -- UI si adatta allo stile di apprendimento
#    gamification JSONB,       -- Esperienza, rami dell'albero abilità esplorati
#    mental_state JSONB        -- Rischio burnout? Giornata leggera oggi!
# );
#
# Perché JSONB e non tabelle classiche per questi dati?
# Perché la gamification cambia spesso. Non vuoi fare 100 migrazioni DB!
```

---

## 🔧 PASSO 13: Kubernetes — Vai in Produzione (DDIA Cap. 6-7, 9)

> **Cosa impari**: Orchestrazione, replicazione, zero-trust, auto-scaling.

```bash
# 1. Avvia cluster locale
minikube start --cpus=4 --memory=8192 --container-runtime=containerd

# 2. Installa dipendenze con Helm
helm repo add redpanda https://charts.redpanda.com
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add kedacore https://kedacore.github.io/charts
helm repo add jetstack https://charts.jetstack.io
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install redpanda redpanda/redpanda -f infra/helm/redpanda-values.yaml
helm install postgresql bitnami/postgresql -f infra/helm/postgres-values.yaml
helm install redis bitnami/redis -f infra/helm/redis-values.yaml
helm install keda kedacore/keda
helm install cert-manager jetstack/cert-manager --set installCRDs=true
helm install vault hashicorp/vault

# 3. Builda e deploya i tuoi servizi
for svc in api-gateway auth-service billing-service chat-service llm-gateway \
  ai-worker user-intelligence-worker assessment-engine user-profile-service \
  cv-analyzer notification-service; do
  podman build -f infra/containers/Containerfile.python-service \
    -t skillforge/$svc:latest services/$svc/
done

# 4. Deploy con Kustomize
kubectl apply -k infra/k8s/overlays/dev/

# 5. KEDA: auto-scaling basato sulla coda
# Se 1000 messaggi in coda → KEDA accende 10 AI Worker
# Se coda vuota → KEDA spegne tutto (scale to zero = costo ZERO!)
```

---

## 🔧 PASSO 14: Sicurezza Bancaria (DDIA Cap. 9, 14)

```bash
# mTLS: ogni servizio ha il suo certificato TLS
# cert-manager li genera e li ruota automaticamente

# Network Policies: zero-trust
# Default: nessun pod può parlare con nessun altro
# Poi allow-list esplicita: "api-gateway può parlare con auth-service"

# Trivy: scansiona le immagini container
trivy image skillforge/api-gateway:latest

# Vault: gestisce tutti i segreti (DB password, API keys, JWT keys)
# MAI nel codice, MAI nelle variabili d'ambiente in chiaro
```

---

## 🔧 PASSO 15: Observability (DDIA Cap. 2, 9)

```bash
# OpenTelemetry: traccia una richiesta attraverso TUTTI i servizi
# Esempio: Request abc-123
#   → API Gateway (2ms)
#     → Redpanda publish (1ms)
#       → AI Worker (3200ms)
#         → LLM Gateway (3100ms)
#           → DeepSeek API (3000ms)
#         → PostgreSQL write (50ms)
# Tutto visibile in Grafana!

# Prometheus: metriche (quante richieste/sec? qual è la latenza p99?)
# Grafana: dashboard per vedere tutto
```

---

## 💰 Matematica del Business

### Costi (per 1.000 utenti attivi)

| Voce | Costo/mese |
|------|-----------|
| Cloud K8s (3 nodi) | ~€100-150 |
| PostgreSQL managed | ~€30-50 |
| LLM API (DeepSeek) | ~€20-50 |
| Dominio + CDN | ~€10 |
| **Totale** | **~€160-260** |

### Ricavi (per 1.000 utenti)

| Conversione | Ricavo/mese |
|-------------|-------------|
| 50 utenti Pro (€9.99) | €499 |
| 10 utenti Enterprise (€29.99) | €299 |
| **Totale** | **€798** |
| **Profitto** | **~€540/mese** |

Con 10.000 utenti: **~€5.400/mese di profitto**.

---

## 📚 Mappa DDIA v2 → SkillForge

| Passo | Cap. DDIA | Cosa Costruisci |
|-------|-----------|-----------------|
| 1. Database | Ch3-4 | Schema PostgreSQL + pgvector + TimescaleDB |
| 2. Auth | Ch8, Ch10 | JWT RS256, bcrypt, ACID, strong consistency |
| 3. API Gateway | Ch2 | FastAPI, SLOs, middleware |
| 4. Event Bus | Ch5, Ch12 | Redpanda, Protobuf, producer/consumer |
| 5. LLM Gateway | Ch1 | Trade-offs, routing, fallback |
| 6. AI Worker | Ch12-13 | Stream processing, idempotenza, DLQ |
| 7. Chat | Ch12 | WebSocket, streaming, real-time |
| 8. Intelligence | Ch13 | Derived data, passive profiling |
| 9. RAG | Ch4 | Vector search, indexes, retrieval |
| 10. Billing | Ch8 | ACID per pagamenti, Stripe webhook |
| 11. CV + Notify | Ch12 | Async processing, object storage |
| 12. Career Ad. | Ch13 | JSONB NoSQL flexibility, Derived intelligence |
| 13. Kubernetes | Ch6-7 | Replicazione, sharding, KEDA |
| 14. Sicurezza | Ch9, Ch14 | mTLS, Vault, GDPR, audit trail |
| 15. Observability | Ch2, Ch9 | Tracing, metriche, dashboard |

---

## 🎯 Quando Avrai Finito

- ✅ **Portfolio da senior engineer** — non un CRUD, un sistema distribuito completo
- ✅ **SaaS funzionante** con pagamenti reali (Stripe)
- ✅ **12 microservizi** su Kubernetes con auto-scaling
- ✅ **Ogni capitolo di DDIA v2** implementato concretamente
- ✅ **Sicurezza bancaria** — mTLS, Vault, audit trail, GDPR
- ✅ **Business reale** che genera profitto da €540/mese (1K utenti) a €5.400/mese (10K)

**Non è solo un progetto — è la prova che sai progettare e costruire sistemi a scala. 🔥**
