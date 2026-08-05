variable "planka_hostname" {
  description = "Public Planka hostname."
  type        = string
  default     = "todo.mauzlab.de"
}

variable "planka_oauth_client_id" {
  description = "OAuth client ID exposed to Planka."
  type        = string
  default     = "planka"
}

variable "planka_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "planka" {
  source = "./modules/oauth_app"

  name      = "Planka"
  slug      = "planka"
  client_id = var.planka_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.planka_hostname}/oidc-callback"
    }
  ]

  client_secret              = var.planka_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.planka_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "planka_homelab_users" {
  target = module.planka.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "planka_homelab_admins" {
  target = module.planka.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "planka_oauth_client_id" {
  description = "Client ID to set as the Planka OIDC client ID."
  value       = module.planka.client_id
}

output "planka_oauth_client_secret" {
  description = "Client secret to set as the Planka OIDC client secret."
  value       = module.planka.client_secret
  sensitive   = true
}

output "planka_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Planka."
  value       = module.planka.redirect_uris[0]
}

output "planka_oidc_issuer_url" {
  description = "OIDC issuer URL to set as the Planka OIDC issuer."
  value       = "${var.authentik_url}/application/o/planka/"
}
