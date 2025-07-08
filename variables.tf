# Variables for Azure App → Confluent Cloud Connector Provisioning

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

variable "existing_identity_provider_id" {
  description = "ID of existing identity provider to use (e.g., op-4N or op-q0G)"
  type        = string
}

variable "azure_app_client_id" {
  description = "Client ID of your Azure AD application"
  type        = string
}