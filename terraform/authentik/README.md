# Authentik Terraform

This stack manages Authentik application/provider resources for homelab OAuth clients.

Managed by default:

- Grafana: OAuth2 provider and application matching `kubernetes/core/monitoring/values.yaml`.
- Paperless-ngx: OIDC provider and application for `https://akten.mauzlab.de`.
- Immich: OIDC provider and application for `https://fotos.mauzlab.de`.
- Argo CD: OIDC provider and application for `https://argocd.mauzlab.de`.
- Kaneo: custom OIDC provider and application for `https://todo.mauzlab.de`.
- Homepage: OIDC provider and application for `https://home.mauzlab.de`.
- Linkding: OIDC provider and application for `https://links.mauzlab.de`.
- pgAdmin: OIDC provider and application for `https://pgadmin.mauzlab.de`.
- Vaultwarden: OIDC provider and application for `https://passwort.mauzlab.de`.
- Mealie: OIDC provider and application for `https://futter.mauzlab.de`.

## Usage

Create an Authentik API token with permission to manage applications and providers, then run:

```bash
cd terraform/authentik
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

After apply, update the `grafana-oauth-secret` sealed secret with:

- `GF_AUTH_GENERIC_OAUTH_CLIENT_ID`: `terraform output -raw grafana_oauth_client_id`
- `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET`: `terraform output -raw grafana_oauth_client_secret`

Grafana expects the Authentik provider to allow `https://grafana.mauzlab.de/login/generic_oauth` and to expose the `openid`, `email`, and `profile` scopes. The `profile` scope includes Authentik group names, which is required by Grafana's `role_attribute_path`.

Paperless-ngx expects the Authentik provider to allow `https://akten.mauzlab.de/accounts/oidc/authentik/login/callback/`. After apply, configure Paperless with:

- `PAPERLESS_APPS`: `allauth.socialaccount.providers.openid_connect`
- `PAPERLESS_SOCIAL_AUTO_SIGNUP`: `true`
- `PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS`: `true`
- `PAPERLESS_ACCOUNT_EMAIL_VERIFICATION`: `none`
- `PAPERLESS_SOCIALACCOUNT_PROVIDERS`: JSON for an `openid_connect` app with `provider_id` set to `authentik`, `client_id` from `terraform output -raw paperless_oauth_client_id`, `secret` from `terraform output -raw paperless_oauth_client_secret`, and `settings.server_url` from `terraform output -raw paperless_oidc_server_url`.

To keep access to data owned by the current local Paperless user, make the Authentik user match the existing Paperless account before the first OIDC login. The low-risk path is to set the Authentik email to the same email as the local Paperless user, keep regular login enabled, sign in locally, and connect the Authentik social account from Paperless account settings if the UI offers it. If Paperless creates a second user instead, stop Paperless and either attach the new `socialaccount_socialaccount.user_id` row to the old `auth_user.id` or move document ownership from the old user to the new one in the database, then start Paperless again. Take a database backup first.

Immich expects the Authentik provider to allow:

- `https://fotos.mauzlab.de/auth/login`
- `https://fotos.mauzlab.de/user-settings`
- `app.immich:///oauth-callback`

After apply, configure Immich OAuth through the Secret-backed config flow in
`kubernetes/apps/immich/README.md` using:

- Issuer URL: `terraform output -raw immich_oidc_discovery_url`
- Client ID: `terraform output -raw immich_oauth_client_id`
- Client secret: `terraform output -raw immich_oauth_client_secret`
- Scope: `openid email profile`
- Signing algorithm: `RS256`
- Token endpoint auth method: `client_secret_post`
- Button text: `Sign in with Authentik`

The Immich chart is configured with `configurationKind: Secret`, but the OAuth
client secret should still stay out of `immich-values.yaml`; values committed to
Git are plaintext Helm inputs. Use a SealedSecret-backed `existingConfiguration`
instead.

Kaneo expects the Authentik provider to allow
`https://todo.mauzlab.de/api/auth/oauth2/callback/custom`. The Helm values in
`kubernetes/apps/kaneo/kaneo-values.yaml` use Authentik's authorization, token,
userinfo, logout, and discovery endpoints and request `openid profile email`.
Password registration, guest access, and the local login form are disabled so
interactive access goes through Authentik. Authentik policy bindings restrict
the application to `homelab-users` and `homelab-admins`.

The chart reads the OAuth client ID and secret from the SealedSecret-backed
`kaneo-oidc-secret`. If `kaneo_oauth_client_secret` is set in local
`terraform.tfvars`, seal that same value. The application session secret and
bundled PostgreSQL password are stored separately in `kaneo-secrets`:

```bash
cd terraform/authentik
terraform apply

cd ../..
kubectl create secret generic kaneo-oidc-secret \
  --namespace kaneo \
  --from-literal=client-id="$(terraform -chdir=terraform/authentik output -raw kaneo_oauth_client_id)" \
  --from-literal=client-secret="$(terraform -chdir=terraform/authentik output -raw kaneo_oauth_client_secret)" \
  --dry-run=client \
  -o yaml \
  | kubeseal --controller-namespace sealed-secrets --format yaml \
  > kubernetes/apps/kaneo/oidc-sealed-secrets.yaml
```

Homepage expects the Authentik provider to allow
`https://home.mauzlab.de/api/auth/callback/homepage-oidc`. Its deployment reads
the OAuth client ID, OAuth client secret, and session encryption secret from the
SealedSecret-backed `homepage-oidc` Secret. The issuer URL is available through
`terraform output -raw homepage_oidc_issuer_url`.

If OIDC access fails, the GitOps rollback is to remove
`HOMEPAGE_AUTH_ENABLED` and the related `HOMEPAGE_OIDC_*`/`HOMEPAGE_AUTH_SECRET`
variables from the Homepage deployment and resync it. Homepage will then return
to its previous unauthenticated behavior.

Linkding expects the Authentik provider to allow
`https://links.mauzlab.de/oidc/callback/`. Its deployment reads the client ID
and secret from the SealedSecret-backed `linkding-oidc` Secret and configures
the Authentik authorization, token, userinfo, and JWKS endpoints directly.
The discovery URL is available through
`terraform output -raw linkding_oidc_discovery_url`.

Linkding matches existing users by email during OIDC login. Ensure an existing
account's email matches its Authentik identity before the first login to avoid
creating a duplicate user. Local login remains enabled as a break-glass path;
only set `LD_DISABLE_LOGIN_FORM=True` after OIDC and API-token clients have
been verified.

pgAdmin expects the Authentik provider to allow
`https://pgadmin.mauzlab.de/oauth2/authorize`. The deployment keeps both
`oauth2` and `internal` authentication enabled and reads the complete
`PGADMIN_CONFIG_OAUTH2_CONFIG` provider list from the SealedSecret-backed
`pgadmin-oidc` Secret. The discovery URL is available through
`terraform output -raw pgadmin_oidc_discovery_url`; the login flow also uses
S256 PKCE.

OAuth users have separate pgAdmin settings and server registrations. Prepare
the matching external user with pgAdmin's `setup.py add-external-user` command
and copy or import any required server registrations before enforcing OAuth-only
authentication. Retain the internal administrator as the break-glass account.

Vaultwarden expects the Authentik provider to allow
`https://passwort.mauzlab.de/identity/connect/oidc-signin`. Its deployment
uses `https://auth.mauzlab.de/application/o/vaultwarden/` as the exact issuer,
requests `profile email offline_access` in addition to Vaultwarden's implicit
`openid` scope, and reads its client credentials from the SealedSecret-backed
`vaultwarden-oidc` Secret.

The provider uses a Vaultwarden-specific email mapping that emits
`email_verified=true`; the managed Authentik email mapping emits `false`, which
Vaultwarden rejects for account linking. Keep `SSO_SIGNUPS_MATCH_EMAIL=true`
only when Authentik's email matches the existing vault account. `SSO_ONLY`
remains false during rollout, and the vault master password is still required
to decrypt vault contents after Authentik authentication.

## Mealie email verification

Mealie v3.21.0 and later require `email_verified=true` for OIDC login. Its
provider replaces Authentik's managed email scope mapping with a Mealie-specific
mapping that asserts verification for nonempty email addresses. Mealie's email
verification check remains enabled.

This follows the homelab's trust model: the administrator controls account
creation and email addresses. Public signup and user changes to unverified email
addresses must remain disabled. The mapping asserts administrator trust; it does
not perform mailbox verification. Revisit it before allowing either capability.

Apply the Authentik Terraform change and start a fresh Mealie login to obtain the
updated claim. No Mealie restart or client-secret change is required.

## Adding OAuth Apps

Add each new client as a root Terraform file named `apps_<app>.tf`. The file should call `./modules/oauth_app`, which creates one OAuth2 provider and one Authentik application.

```hcl
variable "example_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "example" {
  source = "./modules/oauth_app"

  name      = "Example"
  slug      = "example"
  client_id = "example"

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://example.mauzlab.de/oauth/callback"
    }
  ]

  client_secret  = var.example_oauth_client_secret
  launch_url     = "https://example.mauzlab.de"
  scope_mappings = local.default_oauth_scope_mappings
}

output "example_oauth_client_secret" {
  description = "Client secret for the Example OAuth provider."
  value       = module.example.client_secret
  sensitive   = true
}
```

By default, apps should use `local.default_oauth_scope_mappings`, which exposes the Authentik `openid`, `email`, and `profile` scopes. Pass a different `scope_mappings` list when an app needs different managed mappings.

Set existing client secrets through the app-specific sensitive variable when importing an existing provider. Leave the secret unset to let Authentik generate one.
