# Output module information
output "connector_manager_principal_id" {
  description = "Principal ID - Connector manager identity pool"
  value       = module.confluent_identity_pools.connector_manager_principal_id
}

output "terraform_principal_id" {
  description = "Principal ID for Terraform provider OAuth authentication (from step 1)"
  value       = data.terraform_remote_state.bootstrap.outputs.terraform_principal_id
}

output "environment_id" {
  description = "Environment ID"
  value       = module.confluent_identity_pools.environment_id
}

output "cluster_id" {
  description = "Kafka cluster ID"
  value       = module.confluent_identity_pools.cluster_id
}

output "cluster_rest_endpoint" {
  description = "Kafka cluster REST endpoint"
  value       = module.confluent_identity_pools.cluster_rest_endpoint
}

output "connect_api_endpoint" {
  description = "API endpoint for connector management"
  value       = module.confluent_identity_pools.connect_api_endpoint
}

output "oauth_configuration" {
  description = "OAuth configuration"
  value = {
    token_url           = var.oauth_external_token_url
    terraform_client_id = var.oauth_external_client_id
    identity_pool_id    = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
  }
  sensitive = false
}

output "connector_target_topic_name" {
  description = "Connector target topic name"
  value       = confluent_kafka_topic.connector_target_topic.topic_name
}

output "identity_pools_summary" {
  description = "Summary of identity pools created"
  value = {
    connector_manager = {
      id          = module.confluent_identity_pools.connector_manager_pool_id
      principal   = module.confluent_identity_pools.connector_manager_principal_id
      purpose     = "Connector management operations"
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