variable "paperless_hostname" {
  description = "Public Paperless-ngx hostname."
  type        = string
  default     = "akten.mauzlab.de"
}

variable "paperless_oauth_client_id" {
  description = "OAuth client ID exposed to Paperless-ngx."
  type        = string
  default     = "paperless"
}

variable "paperless_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "paperless" {
  source = "./modules/oauth_app"

  name      = "Paperless-ngx"
  slug      = "paperless"
  client_id = var.paperless_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.paperless_hostname}/accounts/oidc/authentik/login/callback/"
    }
  ]

  client_secret              = var.paperless_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.paperless_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "paperless_homelab_users" {
  target = module.paperless.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "paperless_homelab_admins" {
  target = module.paperless.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "paperless_oauth_client_id" {
  description = "Client ID to set in PAPERLESS_SOCIALACCOUNT_PROVIDERS."
  value       = module.paperless.client_id
}

output "paperless_oauth_client_secret" {
  description = "Client secret to set in PAPERLESS_SOCIALACCOUNT_PROVIDERS."
  value       = module.paperless.client_secret
  sensitive   = true
}

output "paperless_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Paperless-ngx."
  value       = module.paperless.redirect_uris[0]
}

output "paperless_oidc_server_url" {
  description = "OIDC server URL to set in PAPERLESS_SOCIALACCOUNT_PROVIDERS."
  value       = "${var.authentik_url}/application/o/paperless/"
}
