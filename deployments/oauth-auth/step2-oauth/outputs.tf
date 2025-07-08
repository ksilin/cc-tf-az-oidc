# Output module information
output "azure_provisioning_principal_id" {
  description = "Principal ID for Azure provisioning application"
  value       = module.confluent_identity_pools.azure_provisioning_principal_id
}

output "terraform_principal_id" {
  description = "Principal ID for Terraform provider OAuth authentication (from step 1)"
  value       = data.terraform_remote_state.bootstrap.outputs.terraform_principal_id
}

output "environment_id" {
  description = "Environment ID for connector provisioning"
  value       = module.confluent_identity_pools.environment_id
}

output "cluster_id" {
  description = "Kafka cluster ID for connector provisioning"
  value       = module.confluent_identity_pools.cluster_id
}

output "cluster_rest_endpoint" {
  description = "Kafka cluster REST endpoint"
  value       = module.confluent_identity_pools.cluster_rest_endpoint
}

output "api_endpoints" {
  description = "Key API endpoints for connector management"
  value       = module.confluent_identity_pools.api_endpoints
}

output "required_azure_scopes" {
  description = "Required Azure AD scopes for token acquisition"
  value       = module.confluent_identity_pools.required_azure_scopes
}

# OAuth deployment specific outputs
output "terraform_identity_pool_id" {
  description = "Identity pool ID used by Terraform provider (from step 1)"
  value       = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
}

output "oauth_configuration" {
  description = "OAuth configuration details"
  value = {
    token_url           = var.oauth_external_token_url
    terraform_client_id = var.oauth_external_client_id
    identity_pool_id    = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
  }
  sensitive = false
}

output "demo_topic_name" {
  description = "Demo topic name"
  value       = confluent_kafka_topic.demo_topic.topic_name
}

output "authentication_method" {
  description = "Authentication method used by this deployment"
  value       = "OAUTH"
}

output "identity_pools_summary" {
  description = "Summary of identity pools created"
  value = {
    provisioning = {
      id          = module.confluent_identity_pools.azure_provisioning_pool_id
      principal   = module.confluent_identity_pools.azure_provisioning_principal_id
      purpose     = "Azure application connector operations"
      permissions = ["CloudClusterAdmin", "ConnectManager", "DeveloperWrite"]
    }
    terraform = {
      id          = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
      principal   = data.terraform_remote_state.bootstrap.outputs.terraform_principal_id
      purpose     = "Terraform infrastructure management (from step 1)"
      permissions = ["EnvironmentAdmin"]
    }
  }
}

# Step deployment information
output "deployment_info" {
  description = "Information about the two-step deployment"
  value = {
    step1_complete      = true
    step2_complete      = true
    terraform_pool_id   = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
    oauth_authenticated = true
  }
}