variable "linkding_hostname" {
  description = "Public Linkding hostname."
  type        = string
  default     = "links.mauzlab.de"
}

variable "linkding_oauth_client_id" {
  description = "OAuth client ID exposed to Linkding."
  type        = string
  default     = "linkding"
}

variable "linkding_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "linkding" {
  source = "./modules/oauth_app"

  name      = "Linkding"
  slug      = "linkding"
  client_id = var.linkding_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.linkding_hostname}/oidc/callback/"
    }
  ]

  client_secret              = var.linkding_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.linkding_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "linkding_homelab_users" {
  target = module.linkding.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "linkding_homelab_admins" {
  target = module.linkding.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "linkding_oauth_client_id" {
  description = "Client ID to set as OIDC_RP_CLIENT_ID."
  value       = module.linkding.client_id
}

output "linkding_oauth_client_secret" {
  description = "Client secret to set as OIDC_RP_CLIENT_SECRET."
  value       = module.linkding.client_secret
  sensitive   = true
}

output "linkding_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Linkding."
  value       = module.linkding.redirect_uris[0]
}

output "linkding_oidc_discovery_url" {
  description = "OIDC discovery URL for the Linkding provider."
  value       = "${var.authentik_url}/application/o/linkding/.well-known/openid-configuration"
}
