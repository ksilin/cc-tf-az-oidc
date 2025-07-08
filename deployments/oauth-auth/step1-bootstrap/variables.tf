# API keys for bootstrap phase
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key for bootstrap phase"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret for bootstrap phase"
  type        = string
  sensitive   = true
}

# OAuth configuration
variable "oauth_external_client_id" {
  description = "Azure AD client ID for Terraform OAuth"
  type        = string
}

variable "existing_identity_provider_id" {
  description = "Existing OIDC identity provider ID (op-4N or op-q0G)"
  type        = string
}

variable "environment_id" {
  description = "Confluent Cloud environment ID"
  type        = string
}