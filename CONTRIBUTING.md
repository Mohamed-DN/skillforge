# 🤝 Contributing to SkillForge

Thank you for your interest in contributing! This document outlines the conventions and workflows used in this project.

---

## 🌿 Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Stable, deployable code |
| `develop` | Integration branch for features |
| `feat/<name>` | New features (`feat/assessment-engine`) |
| `fix/<name>` | Bug fixes (`fix/consumer-idempotency`) |
| `docs/<name>` | Documentation changes |
| `infra/<name>` | Infrastructure changes |
| `refactor/<name>` | Code refactoring |

### Workflow
1. Create a branch from `develop`
2. Make your changes
3. Open a PR to `develop`
4. After review and CI pass, merge
5. `develop` is periodically merged to `main` for releases

---

## 📝 Commit Conventions

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `infra` | Infrastructure changes (K8s, Docker, Terraform) |
| `ci` | CI/CD pipeline changes |
| `style` | Formatting, linting (no code change) |
| `perf` | Performance improvement |
| `chore` | Maintenance tasks |

### Scopes
Use the service or component name: `api-gateway`, `ai-worker`, `database`, `k8s`, `events`, etc.

### Examples
```
feat(api-gateway): add JWT authentication endpoint
fix(ai-worker): handle duplicate events with idempotency check
docs(roadmap): mark Phase 1 as complete
infra(k8s): add KEDA ScaledObject for ai-worker
test(assessment-engine): add RAG query integration tests
```

---

## 🐍 Code Style (Python)

- **Formatter**: Black (line length 100)
- **Import sorting**: isort
- **Linter**: Ruff
- **Type checking**: mypy (strict mode)
- **Python version**: 3.12+

### Pre-commit (coming soon)
```bash
pip install pre-commit
pre-commit install
```

---

## 🧪 Testing

- **Framework**: pytest
- **Coverage**: pytest-cov (target: 80%+)
- **Naming**: `test_<feature>_<scenario>.py`

Run tests:
```bash
# Single service
cd services/api-gateway
pytest tests/ -v

# All tests
pytest --rootdir=. -v
```

---

## 📦 Adding a New Service

1. Create directory under `services/<name>/`
2. Follow the standard structure (see AI_CONTEXT.md)
3. Add a `Dockerfile`
4. Add a `README.md` for the service
5. Add K8s manifests in `infra/k8s/base/<name>/`
6. Add to `infra/docker/docker-compose.yml`
7. Update `AI_CONTEXT.md` with the new service
8. Update `ROADMAP.md` if applicable

---

## 🔑 Secrets

**NEVER commit secrets.** Use:
- `.env` files (gitignored)
- Kubernetes Secrets (for deployment)
- Environment variables in CI/CD

---

## ❓ Questions?

Open an issue or start a discussion in the repository.
