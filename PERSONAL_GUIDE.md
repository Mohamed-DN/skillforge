# 📖 SkillForge — La Tua Guida Personale (Zero → Produzione)

> Questa guida è scritta **solo per te, Mohamed**. Spiega tutto il progetto da zero,
> come costruire ogni pezzo a mano, e cosa imparerai ad ogni passo.

---

## 🧠 Cos'è SkillForge in Parole Semplici

Immagina un'app che:
1. Un utente si registra e carica il suo CV
2. L'IA legge il CV e capisce le sue competenze attuali
3. L'app crea un percorso di apprendimento personalizzato
4. Ogni giorno l'utente fa un quiz adattivo
5. L'IA analizza come risponde (velocità, profondità) e aggiorna il suo profilo
6. Il giorno dopo, il quiz è leggermente diverso — introduce domande di domini adiacenti
7. L'utente cresce senza accorgersene ("stealth learning")

**Il tutto scalabile da 100 a 100.000 utenti** grazie a Kubernetes e auto-scaling.

---

## 🏗️ Come Funziona Tecnicamente (Spiegato Semplice)

### Il Flusso dei Dati
```
Utente → API Gateway → Eventi (Redpanda) → AI Worker → Database → Quiz personalizzato
```

### I Componenti (9 microservizi)

| Servizio | Cosa Fa | Esempio |
|----------|---------|---------|
| **api-gateway** | Riceve le richieste dall'utente | "POST /quiz/answer" |
| **auth-service** | Gestisce login, registrazione, sicurezza | "Chi sei? Hai pagato?" |
| **billing-service** | Gestisce abbonamenti e pagamenti (Stripe) | "Free, Pro, Enterprise" |
| **llm-gateway** | Smista le richieste AI al modello giusto | "Quiz → DeepSeek, CV → Gemini" |
| **ai-worker** | Elabora i dati in background | "Analizza risposta, aggiorna skills" |
| **assessment-engine** | Genera quiz personalizzati | "RAG: cerca materiale simile + genera domande" |
| **user-profile-service** | Gestisce profilo utente e skills | "Vettore competenze, obiettivi" |
| **cv-analyzer** | Legge e analizza i CV | "PDF → Estrazione skills → Vettore iniziale" |
| **notification-service** | Invia notifiche | "Hai completato 7 giorni di fila!" |

### Il Database (un solo PostgreSQL, 3 superpoteri)
```
PostgreSQL = Dati normali (utenti, tabelle)
           + pgvector (ricerca semantica per RAG)
           + TimescaleDB (dati nel tempo per analytics)
```

### L'Event Bus (Redpanda)
Ogni azione dell'utente diventa un **evento immutabile**:
```
"UserAnsweredQuestion" → salvato per sempre → elaborato da chi ne ha bisogno
```

### Perché Podman e non Docker?
| Criterio | Podman | Docker |
|----------|--------|--------|
| **Sicurezza** | ✅ Rootless di default, nessun daemon root | ❌ Daemon root |
| **Costo** | ✅ 100% gratis | ❌ Licenza a pagamento per aziende |
| **Performance** | ✅ 65% meno memoria | ⚠️ Daemon sempre attivo |
| **Kubernetes** | ✅ Genera YAML K8s nativamente | ❌ Serve conversione |

---

## 🔧 Come Costruire Tutto da Zero (Passo per Passo)

### Passo 0: Prepara il tuo Mac

```bash
# Installa Homebrew (se non l'hai già)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installa gli strumenti
brew install python@3.12 podman podman-compose kubectl helm

# Inizializza la macchina Podman (crea la VM Linux)
podman machine init --cpus=4 --memory=8192
podman machine start

# Verifica che tutto funzioni
podman --version
python3.12 --version
kubectl version --client
```

### Passo 1: Database (Capitoli 3-4 del libro DDIA)

**Cosa impari**: Come i dati vengono salvati, indicizzati, e cercati.

```bash
# Avvia PostgreSQL con pgvector e TimescaleDB
podman-compose -f infra/containers/podman-compose.yml up -d postgres

# Connettiti al database
podman exec -it skillforge-postgres psql -U skillforge -d skillforge

# Esegui lo schema
\i /docker-entrypoint-initdb.d/01-schema.sql

# Verifica
\dt   -- lista tabelle
\dx   -- lista estensioni (pgvector, timescaledb)
```

**Prova**: Inserisci un utente manualmente con SQL e verifica.

### Passo 2: API Gateway (Capitolo 2 del libro — Requisiti non-funzionali)

**Cosa impari**: Come scrivere un'API veloce, con autenticazione e documentazione automatica.

```bash
cd services/api-gateway

# Crea virtual environment
python3.12 -m venv .venv
source .venv/bin/activate

# Installa dipendenze
pip install fastapi uvicorn sqlalchemy asyncpg pydantic python-jose[cryptography] passlib[bcrypt]

# Scrivi il tuo primo endpoint in src/main.py
# FastAPI genera automaticamente la documentazione su /docs

# Avvia
uvicorn src.main:app --reload --port 8000

# Apri http://localhost:8000/docs — vedrai la UI di Swagger
```

### Passo 3: Auth Service (Capitolo 8 — Transazioni, Capitolo 10 — Consistenza)

**Cosa impari**: Sicurezza delle password, JWT, come funzionano le sessioni.

```bash
cd services/auth-service

# Le password NON si salvano mai in chiaro!
# bcrypt le trasforma in hash irreversibili:
#   "password123" → "$2b$12$LJ3m4ys3..."

# JWT (JSON Web Token) funziona così:
# 1. Utente fa login con email/password
# 2. Server verifica bcrypt hash
# 3. Server crea un JWT firmato con chiave privata RS256
# 4. Client manda il JWT ad ogni richiesta
# 5. Server verifica la firma con chiave pubblica (velocissimo)
```

### Passo 4: Event Bus — Redpanda (Capitoli 12-13 del libro — Stream Processing)

**Cosa impari**: Come i servizi comunicano senza conoscersi, eventi immutabili.

```bash
# Avvia Redpanda
podman-compose -f infra/containers/podman-compose.yml up -d redpanda

# Crea i topic
podman exec -it skillforge-redpanda rpk topic create assessment.answer --partitions 12

# Apri la Console UI
# http://localhost:8080 — vedrai i topic e i messaggi in tempo reale
```

### Passo 5: LLM Gateway (Capitolo 1 — Trade-offs)

**Cosa impari**: Come gestire più provider AI con una singola interfaccia.

```bash
# LiteLLM ti permette di chiamare qualsiasi LLM con la stessa sintassi:
# litellm.completion(model="deepseek/deepseek-chat", messages=[...])
# litellm.completion(model="gemini/gemini-pro", messages=[...])
# Stessa funzione, modello diverso. Se uno cade, fallback all'altro.
```

### Passo 6: AI Worker (Capitolo 12 — Stream Processing, Capitolo 5 — Encoding)

**Cosa impari**: Consumer groups, idempotenza, dead-letter queues.

```bash
# L'AI Worker è un loop infinito:
# while True:
#     event = consumer.poll()    # Prendi un evento da Redpanda
#     result = llm.analyze(event) # Chiedi all'IA di analizzarlo
#     db.update_vector(result)    # Aggiorna il vettore competenze
#     consumer.commit()           # Conferma: "Ho finito con questo evento"
```

### Passo 7: Assessment Engine + RAG (Capitolo 4 — Storage & Retrieval)

**Cosa impari**: Ricerca vettoriale, come funziona RAG (Retrieval Augmented Generation).

```bash
# RAG in 3 passi:
# 1. RETRIEVE: Cerca materiale simile nel DB (pgvector similarity search)
#    SELECT content FROM learning_materials
#    ORDER BY embedding <=> user_competency_vector LIMIT 5;
#
# 2. AUGMENT: Aggiungi il materiale trovato al prompt dell'IA
#    prompt = f"Basandoti su questo materiale: {materiale}, genera 10 domande..."
#
# 3. GENERATE: L'IA genera le domande personalizzate
```

### Passo 8: Billing (Capitolo 8 — Transazioni ACID)

**Cosa impari**: Pagamenti sicuri, webhook, consistenza strong.

```bash
# Stripe Checkout funziona così:
# 1. Utente clicca "Abbonati a Pro"
# 2. Il backend crea una Stripe Checkout Session
# 3. Utente viene reindirizzato su stripe.com (PCI-compliant, non tocchi mai le carte)
# 4. Stripe processa il pagamento
# 5. Stripe chiama il tuo webhook: "Hey, il pagamento è andato a buon fine!"
# 6. Tu attivi l'abbonamento nel tuo DB (nella stessa transazione: ACID!)
```

### Passo 9: Kubernetes (Capitoli 6-7 — Replicazione e Sharding)

**Cosa impari**: Come deployare, scalare, e rendere tutto resiliente.

```bash
# Installa un cluster locale
brew install minikube
minikube start --cpus=4 --memory=8192 --container-runtime=containerd

# Installa le dipendenze
helm install redpanda redpanda/redpanda -f infra/helm/redpanda-values.yaml
helm install postgresql bitnami/postgresql -f infra/helm/postgres-values.yaml
helm install keda kedacore/keda

# Deploy i tuoi servizi
kubectl apply -k infra/k8s/overlays/dev/

# KEDA: Auto-scaling basato sugli eventi
# Se ci sono 1000 messaggi in coda → KEDA accende 10 AI Worker
# Se la coda è vuota → KEDA spegne tutto (scale to zero, costo zero!)
```

### Passo 10: Sicurezza Bancaria (Capitolo 9 — Problemi dei Sistemi Distribuiti)

```bash
# mTLS tra i servizi (ogni servizio ha il suo certificato)
helm install cert-manager jetstack/cert-manager

# Network Policies: ogni pod può parlare SOLO con chi deve
# Default: deny-all. Poi allow-list esplicita.

# Trivy: scansiona le immagini per vulnerabilità
trivy image skillforge/api-gateway:latest

# Vault: i segreti non sono mai nel codice o nelle variabili d'ambiente
helm install vault hashicorp/vault
```

### Passo 11: Observability (Capitolo 9 — Debugging Distribuito)

```bash
# OpenTelemetry: traccia ogni richiesta attraverso tutti i servizi
# Request ID: abc-123 → API Gateway → Redpanda → AI Worker → LLM → DB
# Vedi il percorso completo in Grafana!

# Prometheus: metriche in tempo reale
# "Quante richieste al secondo?" "Qual è la latenza p99?"

# Grafana: dashboard visuale
# Vedrai: salute del sistema, costi AI, utenti attivi, errori
```

---

## 💰 Matematica del Business

### Costi Stimati (per 1000 utenti attivi)

| Voce | Costo Mensile |
|------|--------------|
| Cloud K8s (3 nodi base) | ~€100-150 |
| PostgreSQL managed | ~€30-50 |
| LLM API (DeepSeek principalmente) | ~€20-50 |
| Dominio + CDN | ~€10 |
| **Totale** | **~€160-260/mese** |

### Ricavi (per 1000 utenti)

| Scenario | Calcolo | Ricavo |
|----------|---------|--------|
| 5% converte a Pro (€9.99) | 50 × €9.99 | €499.50/mese |
| 1% converte a Enterprise (€29.99) | 10 × €29.99 | €299.90/mese |
| **Totale** | | **€799.40/mese** |
| **Profitto** | €799 - €260 | **~€539/mese** |

Con 10.000 utenti e le stesse percentuali: **~€5.390/mese di profitto**.

---

## 📚 Mappatura Libro DDIA v2 → SkillForge

Mentre costruisci ogni pezzo, stai implementando un capitolo del libro:

| Fase | Capitoli DDIA | Cosa Costruisci |
|------|--------------|-----------------|
| Database | Ch3 (Data Models), Ch4 (Storage) | Schema PostgreSQL + pgvector |
| API | Ch2 (Non-functional Reqs) | FastAPI con SLOs |
| Auth | Ch8 (Transactions), Ch10 (Consistency) | JWT, bcrypt, ACID |
| Eventi | Ch5 (Encoding), Ch12 (Stream Processing) | Protobuf + Redpanda |
| AI Worker | Ch12 (Streams), Ch13 (Philosophy) | Consumer idempotente |
| RAG | Ch4 (Retrieval) | pgvector similarity search |
| Billing | Ch8 (Transactions) | Stripe + ACID |
| K8s | Ch6 (Replication), Ch7 (Sharding) | Deploy + autoscaling |
| Sicurezza | Ch9 (Distributed Problems) | mTLS, Vault, network policies |
| GDPR | Ch14 (Doing the Right Thing) | Privacy, consenso, cancellazione |

---

## 🎯 Il Tuo Obiettivo Finale

Quando avrai completato SkillForge, avrai:
- ✅ Un **portfolio project** che dimostra competenze da senior engineer
- ✅ Un'**app SaaS funzionante** con pagamenti reali
- ✅ Competenze pratiche in **9 microservizi**, **Kubernetes**, **AI/LLM**, **event-driven architecture**
- ✅ Implementazione concreta di **ogni capitolo di DDIA v2**
- ✅ Un **business reale** che può generare profitto

**Non è solo un progetto — è la prova che sai progettare e costruire sistemi a scala.**
