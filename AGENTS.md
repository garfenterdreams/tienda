# Saleor (Garfenter Tienda)

## Project Context

This is **Garfenter Tienda** - a customized Saleor e-commerce platform.

| Attribute | Value |
|-----------|-------|
| Domain | `tienda.garfenter.com` |
| Git Remote | `garfenter` → `github.com/garfenterdreams/tienda.git` |
| ECR Image | `144656353217.dkr.ecr.us-east-1.amazonaws.com/garfenter/tienda` |

## Repository Structure

```
/Users/garfenter/development/products/ecommerce/saleor/
├── saleor/                    # Backend API (Python/Django/GraphQL)
├── dashboard/                 # Frontend Dashboard (React/TypeScript)
├── Dockerfile.combined        # Builds combined API + Dashboard image
├── docker-compose.garfenter.yml  # Local development compose
├── nginx/                     # Nginx config for combined image
└── SSO_IMPLEMENTATION.md      # SSO configuration details
```

## SSO Configuration

**SSO-Only Mode** is enabled via `SSO_ONLY_ENABLED=true` environment variable.

- **Backend block**: `saleor/graphql/account/mutations/authentication/create_token.py`
  - Blocks password login when SSO_ONLY_ENABLED=true
- **Frontend auto-redirect**: `dashboard/src/auth/views/Login.tsx`
  - Should auto-redirect to Keycloak when SSO is the only option (TODO)

See `SSO_IMPLEMENTATION.md` for full SSO details.

## Keycloak Integration

| Setting | Value |
|---------|-------|
| Keycloak URL | `https://sso.garfenter.com` |
| Realm | `garfenter` |
| Client ID | `product-tienda` |
| OIDC Plugin ID | `mirumee.authentication.openidconnect` |

## Build & Deploy

```bash
# Push to main triggers GitHub Actions deploy
git push garfenter main

# Manual deploy: builds Dockerfile.combined and pushes to ECR
```

---

# Testing

## Running tests

- Run tests using `pytest`
- Attach `--reuse-db` argument to speed up tests by reusing the test database
- Select tests to run by passing test file path as an argument
- Enter virtual environment before executing tests

## Writing tests

- Use given/when/then structure for clarity
- Use `pytest` fixtures for setup and teardown
- Declare test suites flat in file. Do not wrapp in classes
- Prefer using fixtures over mocking. Fixtures are usually within directory "tests/fixtures" and are functions decorated with`@pytest.fixture`
