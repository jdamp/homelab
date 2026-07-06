variable "name" {
  description = "Authentik application and OAuth2 provider name."
  type        = string
}

variable "slug" {
  description = "Authentik application slug."
  type        = string
}

variable "client_id" {
  description = "OAuth client ID."
  type        = string
}

variable "client_secret" {
  description = "Optional OAuth client secret. Leave null to let Authentik generate one."
  type        = string
  default     = null
  sensitive   = true
}

variable "authorization_flow_id" {
  description = "Authentik authorization flow ID."
  type        = string
}

variable "invalidation_flow_id" {
  description = "Authentik invalidation flow ID."
  type        = string
}

variable "allowed_redirect_uris" {
  description = "OAuth redirect URIs allowed by Authentik."
  type = list(object({
    matching_mode     = optional(string, "strict")
    redirect_uri_type = optional(string)
    url               = string
  }))
}

variable "scope_mappings" {
  description = "Managed Authentik OAuth scope mapping identifiers."
  type        = list(string)
  default = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

variable "property_mapping_ids" {
  description = "Explicit Authentik OAuth property mapping IDs. When unset, IDs are resolved from scope_mappings."
  type        = list(string)
  default     = []
}

variable "access_code_validity" {
  description = "Access code validity duration."
  type        = string
  default     = null
}

variable "access_token_validity" {
  description = "Access token validity duration."
  type        = string
  default     = null
}

variable "authentication_flow" {
  description = "Optional Authentik authentication flow ID."
  type        = string
  default     = null
}

variable "client_type" {
  description = "OAuth client type."
  type        = string
  default     = "confidential"
}

variable "encryption_key" {
  description = "Optional encryption key ID."
  type        = string
  default     = null
}

variable "group" {
  description = "Optional Authentik application group."
  type        = string
  default     = null
}

variable "grant_types" {
  description = "OAuth grant types allowed for this provider."
  type        = list(string)
  default     = null
}

variable "include_claims_in_id_token" {
  description = "Include provider claims in the ID token."
  type        = bool
  default     = true
}

variable "issuer_mode" {
  description = "OAuth issuer mode."
  type        = string
  default     = "global"
}

variable "launch_url" {
  description = "Application launch URL shown in Authentik."
  type        = string
  default     = null
}

variable "logout_uri" {
  description = "Optional OAuth logout URI."
  type        = string
  default     = null
}

variable "meta_description" {
  description = "Optional Authentik application description."
  type        = string
  default     = null
}

variable "meta_icon" {
  description = "Optional Authentik application icon URL."
  type        = string
  default     = null
}

variable "meta_publisher" {
  description = "Optional Authentik application publisher."
  type        = string
  default     = null
}

variable "open_in_new_tab" {
  description = "Open the application launch URL in a new tab."
  type        = bool
  default     = true
}

variable "refresh_token_threshold" {
  description = "Refresh token threshold duration."
  type        = string
  default     = null
}

variable "refresh_token_validity" {
  description = "Refresh token validity duration."
  type        = string
  default     = null
}

variable "signing_key" {
  description = "Optional signing key ID."
  type        = string
  default     = null
}

variable "sub_mode" {
  description = "OAuth subject mode."
  type        = string
  default     = null
}
