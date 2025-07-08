# Confluent Cloud Authentication (API Key method)
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

# Core Configuration
variable "existing_identity_provider_id" {
  description = "ID of existing identity provider to use (e.g., op-4N or op-q0G)"
  type        = string
}

variable "environment_id" {
  description = "ID of the Confluent Cloud environment"
  type        = string
  default     = "env-nvv5xz"
}

variable "azure_app_client_id" {
  description = "Client ID of your Azure AD application for connector operations"
  type        = string
}