# Tienda SSO Implementation Notes

## Repository Structure

| Component | Location |
|-----------|----------|
| Saleor API (Backend) | `/Users/garfenter/development/products/ecommerce/saleor/` |
| Dashboard (Frontend) | `/Users/garfenter/development/products/ecommerce/saleor/dashboard/` |
| Combined Dockerfile | `/Users/garfenter/development/products/ecommerce/saleor/Dockerfile.combined` |
| Git Remote | `garfenter` → `github.com/garfenterdreams/tienda.git` |

## Domain Mapping

| URL | Component |
|-----|-----------|
| `https://tienda.garfenter.com/` | Dashboard (served from `/app/dashboard/`) |
| `https://tienda.garfenter.com/graphql/` | Saleor API |
| `https://tienda.garfenter.com/dashboard/` | Dashboard alternate path |

## SSO Configuration

### Backend (API) - SSO-Only Mode

**File:** `saleor/graphql/account/mutations/authentication/create_token.py`

The `CreateToken` mutation checks `SSO_ONLY_ENABLED` env var and blocks password login:

```python
def is_sso_only_enabled() -> bool:
    return os.environ.get("SSO_ONLY_ENABLED", "").lower() in ("true", "1", "yes")

# In perform_mutation:
if is_sso_only_enabled():
    raise ValidationError({"email": ValidationError(
        "Password authentication is disabled. Please use SSO to login.",
        code=AccountErrorCode.INVALID_CREDENTIALS.value,
    )})
```

### Frontend (Dashboard) - Auto-Redirect to SSO

**File:** `dashboard/src/auth/views/Login.tsx`

The Dashboard needs modification to auto-redirect to Keycloak when:
1. `SSO_ONLY_ENABLED=true` (or when only one external auth is available)
2. User is not authenticated
3. Not already in callback flow

Key functions:
- `queryExternalAuthentications()` - Fetches available SSO providers
- `handleRequestExternalAuthentication(pluginId)` - Redirects to SSO provider
- `externalAuthentications?.shop?.availableExternalAuthentications` - List of SSO options

### OIDC Plugin Configuration

The OpenID Connect plugin is configured via GraphQL mutation (NOT environment variables):

```graphql
mutation {
  pluginUpdate(id: "mirumee.authentication.openidconnect", input: {
    active: true,
    configuration: [
      {name: "client_id", value: "product-tienda"},
      {name: "client_secret", value: "plmf07z5UjUicajh0MPlJ9R0e7uLGUMM"},
      {name: "oauth_authorization_url", value: "https://sso.garfenter.com/realms/garfenter/protocol/openid-connect/auth"},
      // ... other OIDC endpoints
    ]
  }) { ... }
}
```

## Build & Deploy

The `Dockerfile.combined` builds both API and Dashboard:
1. Stage 1: Builds Dashboard with pnpm/vite
2. Stage 2: Builds Python dependencies
3. Stage 3: Combines into final image with nginx + supervisord

GitHub Actions workflow: `.github/workflows/deploy.yml`
- Pushes to ECR: `144656353217.dkr.ecr.us-east-1.amazonaws.com/garfenter/tienda`

## TODO: Auto-Redirect Implementation

Modify `dashboard/src/auth/views/Login.tsx` to add auto-redirect:

```typescript
useEffect(() => {
  // Auto-redirect to SSO if it's the only auth method
  const externalAuths = externalAuthentications?.shop?.availableExternalAuthentications;
  if (externalAuths?.length === 1 && !isCallbackPath && !authenticating) {
    handleRequestExternalAuthentication(externalAuths[0].id);
  }
}, [externalAuthentications, isCallbackPath, authenticating]);
```

## Credentials Reference

| Credential | Value |
|------------|-------|
| Keycloak Client ID | `product-tienda` |
| Keycloak Client Secret | `plmf07z5UjUicajh0MPlJ9R0e7uLGUMM` |
| Keycloak Realm | `garfenter` |
| Keycloak URL | `https://sso.garfenter.com` |
