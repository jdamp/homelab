variable "vaultwarden_hostname" {
  description = "Public Vaultwarden hostname."
  type        = string
  default     = "passwort.mauzlab.de"
}

variable "vaultwarden_oauth_client_id" {
  description = "OAuth client ID exposed to Vaultwarden."
  type        = string
  default     = "vaultwarden"
}

variable "vaultwarden_oauth_client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

data "authentik_property_mapping_provider_scope" "vaultwarden_builtin" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
    "goauthentik.io/providers/oauth2/scope-offline_access",
  ]
}

# Vaultwarden rejects SSO account creation and linking unless the identity
# provider explicitly marks the email as verified. This mapping is scoped only
# to this provider; access is additionally limited by the application bindings.
resource "authentik_property_mapping_provider_scope" "vaultwarden_email" {
  name       = "Vaultwarden OAuth Mapping: verified email"
  scope_name = "email"
  expression = <<-EOT
    if not request.user.email:
        return {}

    return {
        "email": request.user.email,
        "email_verified": True,
    }
  EOT
}

module "vaultwarden" {
  source = "./modules/oauth_app"

  name      = "Vaultwarden"
  slug      = "vaultwarden"
  client_id = var.vaultwarden_oauth_client_id

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.vaultwarden_hostname}/identity/connect/oidc-signin"
    }
  ]

  client_secret              = var.vaultwarden_oauth_client_secret
  client_type                = "confidential"
  grant_types                = ["authorization_code", "refresh_token"]
  group                      = "Core"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://${var.vaultwarden_hostname}"
  open_in_new_tab            = false
  refresh_token_threshold    = "hours=1"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  property_mapping_ids = concat(
    data.authentik_property_mapping_provider_scope.vaultwarden_builtin.ids,
    [authentik_property_mapping_provider_scope.vaultwarden_email.id],
  )
}

resource "authentik_policy_binding" "vaultwarden_homelab_users" {
  target = module.vaultwarden.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "vaultwarden_homelab_admins" {
  target = module.vaultwarden.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "vaultwarden_oauth_client_id" {
  description = "Client ID to set as SSO_CLIENT_ID."
  value       = module.vaultwarden.client_id
}

output "vaultwarden_oauth_client_secret" {
  description = "Client secret to set as SSO_CLIENT_SECRET."
  value       = module.vaultwarden.client_secret
  sensitive   = true
}

output "vaultwarden_oauth_redirect_uri" {
  description = "Redirect URI configured in Authentik for Vaultwarden."
  value       = module.vaultwarden.redirect_uris[0]
}

output "vaultwarden_oidc_issuer_url" {
  description = "OIDC issuer URL to set as SSO_AUTHORITY."
  value       = "${var.authentik_url}/application/o/vaultwarden/"
}
