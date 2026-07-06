output "application_slug" {
  description = "Authentik application slug."
  value       = authentik_application.this.slug
}

output "application_uuid" {
  description = "Authentik application UUID."
  value       = authentik_application.this.uuid
}

output "client_id" {
  description = "OAuth client ID."
  value       = authentik_provider_oauth2.this.client_id
}

output "client_secret" {
  description = "OAuth client secret."
  value       = authentik_provider_oauth2.this.client_secret
  sensitive   = true
}

output "redirect_uris" {
  description = "Redirect URIs configured in Authentik."
  value       = [for redirect_uri in var.allowed_redirect_uris : redirect_uri.url]
}
