# Authentik Terraform

This stack manages Authentik application/provider resources for homelab OAuth clients.

Managed by default:

- Grafana: OAuth2 provider and application matching `kubernetes/core/monitoring/values.yaml`.
- Paperless-ngx: OIDC provider and application for `https://akten.mauzlab.de`.
- Immich: OIDC provider and application for `https://fotos.mauzlab.de`.
- Argo CD: OIDC provider and application for `https://argocd.mauzlab.de`.
- Planka: OIDC provider and application for `https://todo.mauzlab.de`.

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

Planka expects the Authentik provider to allow `https://todo.mauzlab.de/oidc-callback`.
The Helm values in `kubernetes/apps/planka/planka-values.yaml` stage:

- Issuer URL: `terraform output -raw planka_oidc_issuer_url`
- Client ID: `terraform output -raw planka_oauth_client_id`
- Client secret: `terraform output -raw planka_oauth_client_secret`
- Scope: `openid profile email`
- Admin role: `homelab-admins`

The Planka chart reads OIDC credentials from a Secret named `planka-oidc-secret`
with keys `clientId` and `clientSecret`. Keep OIDC disabled until the sealed
secret exists. If you set `planka_oauth_client_secret` in local
`terraform.tfvars`, seal that same value:

```bash
cd terraform/authentik
terraform apply

cd ../..
kubectl create secret generic planka-oidc-secret \
  --namespace planka \
  --from-literal=clientId="$(terraform -chdir=terraform/authentik output -raw planka_oauth_client_id)" \
  --from-literal=clientSecret="$(terraform -chdir=terraform/authentik output -raw planka_oauth_client_secret)" \
  --dry-run=client \
  -o yaml \
  | kubeseal --controller-namespace sealed-secrets --format yaml \
  > kubernetes/apps/planka/oidc-sealed-secrets.yaml
```

Then set `oidc.enabled: true` in `kubernetes/apps/planka/planka-values.yaml`
and add `oidc-sealed-secrets.yaml` to `kubernetes/apps/planka/kustomization.yaml`.

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
