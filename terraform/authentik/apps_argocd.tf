variable "argocd_hostname" {
  description = "Public Argo CD hostname."
  type        = string
  default     = "argocd.mauzlab.de"
}

variable "argocd_oauth_client_id" {
  description = "OAuth client ID exposed to Argo CD."
  type        = string
  default     = "argocd"
}

variable "argocd_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

module "argocd" {
  source = "./modules/oauth_app"

  name      = "Argo CD"
  slug      = "argocd"
  client_id = var.argocd_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.argocd_hostname}/api/dex/callback"
    }
  ]

  client_secret              = var.argocd_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.argocd_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "argocd_homelab_users" {
  target = module.argocd.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "argocd_homelab_admins" {
  target = module.argocd.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "argocd_oauth_client_id" {
  description = "Client ID used by the Argo CD Authentik connector."
  value       = module.argocd.client_id
}

output "argocd_oauth_client_secret" {
  description = "Client secret used by the Argo CD Authentik connector."
  value       = module.argocd.client_secret
  sensitive   = true
}

output "argocd_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Argo CD."
  value       = module.argocd.redirect_uris[0]
}

output "argocd_oidc_issuer_url" {
  description = "OIDC issuer URL used by Argo CD's Dex connector."
  value       = "${var.authentik_url}/application/o/${module.argocd.application_slug}/"
}
