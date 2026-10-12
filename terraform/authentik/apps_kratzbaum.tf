variable "kratzbaum_hostname" {
  description = "Public Kratzbaum hostname."
  type        = string
  default     = "kratzbaum.mauzlab.de"
}

variable "kratzbaum_oauth_client_id" {
  description = "OAuth client ID exposed to Kratzbaum."
  type        = string
  default     = "kratzbaum"
}

variable "kratzbaum_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "kratzbaum" {
  source = "./modules/oauth_app"

  name      = "Kratzbaum"
  slug      = "kratzbaum"
  client_id = var.kratzbaum_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.kratzbaum_hostname}/auth/callback"
    }
  ]

  client_secret              = var.kratzbaum_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.kratzbaum_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "kratzbaum_homelab_users" {
  target = module.kratzbaum.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "kratzbaum_homelab_admins" {
  target = module.kratzbaum.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "kratzbaum_oauth_client_id" {
  description = "Client ID configured as OIDC_CLIENT_ID."
  value       = module.kratzbaum.client_id
}

output "kratzbaum_oauth_client_secret" {
  description = "Client secret configured as OIDC_CLIENT_SECRET."
  value       = module.kratzbaum.client_secret
  sensitive   = true
}

output "kratzbaum_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Kratzbaum."
  value       = module.kratzbaum.redirect_uris[0]
}

output "kratzbaum_oidc_discovery_url" {
  description = "OIDC discovery URL for the Kratzbaum provider."
  value       = "${var.authentik_url}/application/o/kratzbaum/.well-known/openid-configuration"
}
