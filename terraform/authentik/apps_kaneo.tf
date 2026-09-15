variable "kaneo_hostname" {
  description = "Public Kaneo hostname."
  type        = string
  default     = "todo.mauzlab.de"
}

variable "kaneo_oauth_client_id" {
  description = "OAuth client ID exposed to Kaneo."
  type        = string
  default     = "kaneo"
}

variable "kaneo_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

moved {
  from = module.planka
  to   = module.kaneo
}

module "kaneo" {
  source = "./modules/oauth_app"

  name      = "Kaneo"
  slug      = "kaneo"
  client_id = var.kaneo_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.kaneo_hostname}/api/auth/oauth2/callback/custom"
    }
  ]

  client_secret              = var.kaneo_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.kaneo_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

moved {
  from = authentik_policy_binding.planka_homelab_users
  to   = authentik_policy_binding.kaneo_homelab_users
}

resource "authentik_policy_binding" "kaneo_homelab_users" {
  target = module.kaneo.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

moved {
  from = authentik_policy_binding.planka_homelab_admins
  to   = authentik_policy_binding.kaneo_homelab_admins
}

resource "authentik_policy_binding" "kaneo_homelab_admins" {
  target = module.kaneo.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "kaneo_oauth_client_id" {
  description = "Client ID to set as the Kaneo custom OIDC client ID."
  value       = module.kaneo.client_id
}

output "kaneo_oauth_client_secret" {
  description = "Client secret to set as the Kaneo custom OIDC client secret."
  value       = module.kaneo.client_secret
  sensitive   = true
}

output "kaneo_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Kaneo."
  value       = module.kaneo.redirect_uris[0]
}

output "kaneo_oidc_discovery_url" {
  description = "OIDC discovery URL to set in Kaneo."
  value       = "${var.authentik_url}/application/o/kaneo/.well-known/openid-configuration"
}
