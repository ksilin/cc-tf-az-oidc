# Core Identity Provider Configuration
variable "identity_provider_id" {
  description = "ID of existing identity provider to use (e.g., op-4N or op-q0G)"
  type        = string
}

variable "environment_id" {
  description = "ID of the Confluent Cloud environment"
  type        = string
}

# Azure Application Configuration
variable "azure_app_client_id" {
  description = "Client ID of your Azure AD application for connector operations"
  type        = string
}

variable "terraform_client_id" {
  description = "Client ID of Azure AD application for Terraform provider (optional, for OAuth setup)"
  type        = string
  default     = null
}

# Identity Pool Configuration
variable "provisioning_pool_name" {
  description = "Display name for the provisioning identity pool"
  type        = string
  default     = "Azure-Connector-Provisioning-Pool"
}

variable "provisioning_pool_description" {
  description = "Description for the provisioning identity pool"
  type        = string
  default     = "Identity pool for Azure application to provision Confluent Cloud connectors"
}

variable "terraform_pool_name" {
  description = "Display name for the Terraform identity pool"
  type        = string
  default     = "Terraform-Infrastructure-Pool"
}

variable "identity_claim" {
  description = "The JWT claim to use for identity mapping"
  type        = string
  default     = "claims.sub"
}

variable "provisioning_filter" {
  description = "Filter expression to match your Azure application for connector operations"
  type        = string
  default     = null
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name for the Kafka cluster"
  type        = string
  default     = "az-connect-cluster"
}

variable "cloud" {
  description = "Cloud provider for the cluster"
  type        = string
  default     = "AZURE"
}

variable "region" {
  description = "Region for the cluster"
  type        = string
  default     = "germanywestcentral"
}

# Optional Features
variable "create_terraform_pool" {
  description = "Whether to create an identity pool for Terraform provider authentication"
  type        = bool
  default     = false
}

variable "create_demo_topic" {
  description = "Whether to create a demo topic"
  type        = bool
  default     = true
}

variable "demo_topic_name" {
  description = "Name for the demo topic"
  type        = string
  default     = "connector-demo-topic"
}