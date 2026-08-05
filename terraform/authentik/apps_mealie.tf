variable "mealie_hostname" {
  description = "Public Mealie hostname."
  type        = string
  default     = "futter.mauzlab.de"
}

data "authentik_property_mapping_provider_scope" "mealie_default" {
  managed_list = local.default_oauth_scope_mappings
}

resource "authentik_property_mapping_provider_scope" "mealie_groups" {
  name       = "Mealie OAuth Mapping: groups"
  scope_name = "groups"
  expression = <<-EOT
    return {
      "groups": [group.name for group in request.user.groups.all()],
    }
  EOT
}

module "mealie" {
  source = "./modules/oauth_app"

  name      = "Mealie"
  slug      = "mealie"
  client_id = "mealie"

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.mealie_hostname}/login"
    },
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://${var.mealie_hostname}/login?direct=1"
    }
  ]

  client_type     = "confidential"
  grant_types     = ["authorization_code"]
  group           = "Core"
  issuer_mode     = "per_provider"
  launch_url      = "https://${var.mealie_hostname}"
  open_in_new_tab = false
  signing_key     = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  property_mapping_ids = concat(
    data.authentik_property_mapping_provider_scope.mealie_default.ids,
    [authentik_property_mapping_provider_scope.mealie_groups.id],
  )
}

resource "authentik_policy_binding" "mealie_homelab_users" {
  target = module.mealie.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "mealie_homelab_admins" {
  target = module.mealie.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "mealie_oauth_client_id" {
  description = "Client ID to set as OIDC_CLIENT_ID."
  value       = module.mealie.client_id
}

output "mealie_oauth_client_secret" {
  description = "Client secret to set as OIDC_CLIENT_SECRET."
  value       = module.mealie.client_secret
  sensitive   = true
}

output "mealie_oauth_redirect_uris" {
  description = "Redirect URIs configured in Authentik for Mealie."
  value       = module.mealie.redirect_uris
}

output "mealie_oidc_discovery_url" {
  description = "OIDC discovery URL to set as OIDC_CONFIGURATION_URL."
  value       = "${var.authentik_url}/application/o/mealie/.well-known/openid-configuration"
}
