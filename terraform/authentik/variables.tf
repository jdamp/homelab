variable "authentik_url" {
  description = "Authentik API URL."
  type        = string
  default     = "https://auth.mauzlab.de"
}

variable "authentik_token" {
  description = "Authentik API token used by Terraform."
  type        = string
  sensitive   = true
}

variable "authentik_insecure" {
  description = "Skip TLS verification when connecting to Authentik."
  type        = bool
  default     = false
}

variable "authorization_flow_slug" {
  description = "Authentik provider authorization flow slug."
  type        = string
  default     = "default-provider-authorization-implicit-consent"
}

variable "invalidation_flow_slug" {
  description = "Authentik provider invalidation flow slug."
  type        = string
  default     = "default-provider-invalidation-flow"
}
