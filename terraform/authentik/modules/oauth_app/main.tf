data "authentik_property_mapping_provider_scope" "this" {
  managed_list = var.scope_mappings
}

resource "authentik_provider_oauth2" "this" {
  name      = var.name
  client_id = var.client_id

  authorization_flow = var.authorization_flow_id
  invalidation_flow  = var.invalidation_flow_id

  access_code_validity       = var.access_code_validity
  access_token_validity      = var.access_token_validity
  allowed_redirect_uris      = var.allowed_redirect_uris
  authentication_flow        = var.authentication_flow
  client_secret              = var.client_secret
  client_type                = var.client_type
  encryption_key             = var.encryption_key
  grant_types                = var.grant_types
  include_claims_in_id_token = var.include_claims_in_id_token
  issuer_mode                = var.issuer_mode
  logout_uri                 = var.logout_uri
  property_mappings          = length(var.property_mapping_ids) > 0 ? var.property_mapping_ids : data.authentik_property_mapping_provider_scope.this.ids
  refresh_token_threshold    = var.refresh_token_threshold
  refresh_token_validity     = var.refresh_token_validity
  signing_key                = var.signing_key
  sub_mode                   = var.sub_mode
}

resource "authentik_application" "this" {
  name              = var.name
  slug              = var.slug
  protocol_provider = authentik_provider_oauth2.this.id

  group            = var.group
  meta_description = var.meta_description
  meta_icon        = var.meta_icon
  meta_launch_url  = var.launch_url
  meta_publisher   = var.meta_publisher
  open_in_new_tab  = var.open_in_new_tab
}
