variable "pgadmin_hostname" {
  description = "Public pgAdmin hostname."
  type        = string
  default     = "pgadmin.mauzlab.de"
}

variable "pgadmin_oauth_client_id" {
  description = "OAuth client ID exposed to pgAdmin."
  type        = string
  default     = "pgadmin"
}

variable "pgadmin_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "pgadmin" {
  source = "./modules/oauth_app"

  name      = "pgAdmin"
  slug      = "pgadmin"
  client_id = var.pgadmin_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.pgadmin_hostname}/oauth2/authorize"
    }
  ]

  client_secret              = var.pgadmin_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.pgadmin_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "pgadmin_homelab_users" {
  target = module.pgadmin.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "pgadmin_homelab_admins" {
  target = module.pgadmin.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "pgadmin_oauth_client_id" {
  description = "Client ID configured in pgAdmin's OAUTH2_CONFIG."
  value       = module.pgadmin.client_id
}

output "pgadmin_oauth_client_secret" {
  description = "Client secret configured in pgAdmin's OAUTH2_CONFIG."
  value       = module.pgadmin.client_secret
  sensitive   = true
}

output "pgadmin_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for pgAdmin."
  value       = module.pgadmin.redirect_uris[0]
}

output "pgadmin_oidc_discovery_url" {
  description = "OIDC discovery URL for the pgAdmin provider."
  value       = "${var.authentik_url}/application/o/pgadmin/.well-known/openid-configuration"
}
