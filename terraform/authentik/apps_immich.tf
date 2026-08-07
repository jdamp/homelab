variable "immich_hostname" {
  description = "Public Immich hostname."
  type        = string
  default     = "fotos.mauzlab.de"
}

variable "immich_oauth_client_id" {
  description = "OAuth client ID exposed to Immich."
  type        = string
  default     = "immich"
}

variable "immich_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "immich" {
  source = "./modules/oauth_app"

  name      = "Immich"
  slug      = "immich"
  client_id = var.immich_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.immich_hostname}/auth/login"
    },
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.immich_hostname}/user-settings"
    },
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "app.immich:///oauth-callback"
    }
  ]

  client_secret              = var.immich_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.immich_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "immich_homelab_users" {
  target = module.immich.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "immich_homelab_admins" {
  target = module.immich.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "immich_oauth_client_id" {
  description = "Client ID to set as the Immich OAuth client ID."
  value       = module.immich.client_id
}

output "immich_oauth_client_secret" {
  description = "Client secret to set as the Immich OAuth client secret."
  value       = module.immich.client_secret
  sensitive   = true
}

output "immich_oauth_redirect_uris" {
  description = "Redirect URIs configured in Authentik for Immich."
  value       = module.immich.redirect_uris
}

output "immich_oidc_discovery_url" {
  description = "OIDC discovery URL to set as the Immich OAuth issuer URL."
  value       = "${var.authentik_url}/application/o/immich/.well-known/openid-configuration"
}
