variable "grafana_hostname" {
  description = "Public Grafana hostname."
  type        = string
  default     = "grafana.mauzlab.de"
}

variable "grafana_oauth_client_id" {
  description = "OAuth client ID exposed to Grafana."
  type        = string
  default     = "grafana"
}

variable "grafana_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "grafana" {
  source = "./modules/oauth_app"

  name      = "Grafana"
  slug      = "grafana"
  client_id = var.grafana_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.grafana_hostname}/login/generic_oauth"
    }
  ]

  access_token_validity      = "minutes=5"
  client_secret              = var.grafana_oauth_client_secret
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  logout_uri                 = "https://${var.grafana_hostname}/logout"
  open_in_new_tab            = false
  scope_mappings             = local.default_oauth_scope_mappings
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
}

output "grafana_application_slug" {
  description = "Authentik application slug for Grafana."
  value       = module.grafana.application_slug
}

output "grafana_oauth_client_id" {
  description = "Client ID to set as GF_AUTH_GENERIC_OAUTH_CLIENT_ID."
  value       = module.grafana.client_id
}

output "grafana_oauth_client_secret" {
  description = "Client secret to set as GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET."
  value       = module.grafana.client_secret
  sensitive   = true
}

output "grafana_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Grafana."
  value       = module.grafana.redirect_uris[0]
}
