# OAuth configuration for Terraform provider
variable "oauth_external_token_url" {
  description = "Azure AD OAuth token endpoint URL"
  type        = string
}

variable "oauth_external_client_id" {
  description = "Azure AD client ID for Terraform OAuth"
  type        = string
}

variable "oauth_external_client_secret" {
  description = "Azure AD client secret for Terraform OAuth"
  type        = string
  sensitive   = true
}

variable "oauth_external_token_scope" {
  description = "OAuth scope for token acquisition (undocumented provider parameter)"
  type        = string
  default     = "https://graph.microsoft.com/.default"
}

# Core configuration
variable "existing_identity_provider_id" {
  description = "Existing OIDC identity provider ID (op-4N or op-q0G)"
  type        = string
}

variable "environment_id" {
  description = "Confluent Cloud environment ID"
  type        = string
}

variable "azure_app_client_id" {
  description = "Azure AD client ID for connector operations"
  type        = string
}

# Optional: Use separate apps for Terraform vs connectors
variable "use_separate_connector_app" {
  description = "Use separate Azure application for connector operations"
  type        = bool
  default     = false
}