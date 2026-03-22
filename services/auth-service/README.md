# Auth Service

Full authentication & authorization service for SkillForge.

## Security Features (Bank-Level)
- **OAuth2 / OpenID Connect** — Standard auth flows
- **bcrypt** — Password hashing (cost factor 12+, adaptive)
- **JWT (RS256)** — Asymmetric key signing (public key verification)
- **Refresh tokens** — Stored in Redis, rotated on each use
- **RBAC** — Role-based access: `admin`, `learner`, `premium`
- **MFA-ready** — TOTP (Google Authenticator), future: WebAuthn/FIDO2
- **Brute-force protection** — Rate limiting on login (5 attempts / 15 min per IP)
- **Session management** — Redis-backed, configurable TTL
- **Password reset** — Time-limited cryptographic tokens (30 min expiry)
- **Account lockout** — After N failed attempts, require email verification

## GDPR Endpoints
- `GET /gdpr/export` — Export all user data (JSON)
- `DELETE /gdpr/erase` — Right to erasure (cascading delete + audit log)
- `GET /gdpr/consent` — View consent records
- `POST /gdpr/consent` — Update consent preferences

## API Endpoints
- `POST /auth/register` — Register new user
- `POST /auth/login` — Login, returns JWT + refresh token
- `POST /auth/refresh` — Refresh JWT using refresh token
- `POST /auth/logout` — Invalidate session + blacklist token
- `POST /auth/password/reset` — Request password reset
- `POST /auth/password/change` — Change password (authenticated)
- `GET /auth/me` — Get current user info
- `POST /auth/mfa/enable` — Enable MFA
- `POST /auth/mfa/verify` — Verify MFA code

## Tech
- FastAPI + Uvicorn
- python-jose (JWT RS256)
- passlib + bcrypt
- Redis (sessions, token blacklist)
- SQLAlchemy (user credentials)
- pyotp (TOTP for MFA)

## Running
```bash
cd services/auth-service
pip install -r requirements.txt
uvicorn src.main:app --reload --port 8005
```
