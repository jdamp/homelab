variable "homepage_hostname" {
  description = "Public Homepage hostname."
  type        = string
  default     = "home.mauzlab.de"
}

variable "homepage_oauth_client_id" {
  description = "OAuth client ID exposed to Homepage."
  type        = string
  default     = "homepage"
}

variable "homepage_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "homepage" {
  source = "./modules/oauth_app"

  name      = "Homepage"
  slug      = "homepage"
  client_id = var.homepage_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.homepage_hostname}/api/auth/callback/homepage-oidc"
    }
  ]

  client_secret              = var.homepage_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.homepage_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "homepage_homelab_users" {
  target = module.homepage.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "homepage_homelab_admins" {
  target = module.homepage.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "homepage_oauth_client_id" {
  description = "Client ID to set as HOMEPAGE_OIDC_CLIENT_ID."
  value       = module.homepage.client_id
}

output "homepage_oauth_client_secret" {
  description = "Client secret to set as HOMEPAGE_OIDC_CLIENT_SECRET."
  value       = module.homepage.client_secret
  sensitive   = true
}

output "homepage_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Homepage."
  value       = module.homepage.redirect_uris[0]
}

output "homepage_oidc_issuer_url" {
  description = "OIDC issuer URL to set as HOMEPAGE_OIDC_ISSUER."
  value       = "${var.authentik_url}/application/o/homepage/"
}
