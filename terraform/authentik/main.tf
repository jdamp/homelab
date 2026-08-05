locals {
  default_oauth_scope_mappings = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

data "authentik_flow" "authorization" {
  slug = var.authorization_flow_slug
}

data "authentik_flow" "invalidation" {
  slug = var.invalidation_flow_slug
}

data "authentik_group" "homelab_users" {
  name = "homelab-users"
}

data "authentik_group" "homelab_admins" {
  name = "homelab-admins"
}
