module "penpot" {
  source = "./modules/oauth_app"

  name      = "Penpot"
  slug      = "penpot"
  client_id = "penpot"

  authorization_flow_id = data.authentik_flow.authorization.id
  invalidation_flow_id  = data.authentik_flow.invalidation.id
  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://design.mauzlab.de/api/auth/oidc/callback"
    }
  ]

  client_type                = "confidential"
  grant_types                = ["authorization_code"]
  group                      = "Apps"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  launch_url                 = "https://design.mauzlab.de"
  signing_key                = "0f5d4208-fad4-47aa-90ef-4b7ffd548fc8"
  scope_mappings             = local.default_oauth_scope_mappings
}

resource "authentik_policy_binding" "penpot_homelab_users" {
  target = module.penpot.application_uuid
  group  = data.authentik_group.homelab_users.id
  order  = 0
}

resource "authentik_policy_binding" "penpot_homelab_admins" {
  target = module.penpot.application_uuid
  group  = data.authentik_group.homelab_admins.id
  order  = 1
}

output "penpot_oauth_client_secret" {
  description = "Client secret for the Penpot sealed secret."
  value       = module.penpot.client_secret
  sensitive   = true
}
