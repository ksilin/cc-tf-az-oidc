# Output module information
output "azure_provisioning_principal_id" {
  description = "Principal ID for Azure provisioning application"
  value       = module.confluent_identity_pools.azure_provisioning_principal_id
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

output "connect_api_endpoint" {
  description = "API endpoint for connector management"
  value       = module.confluent_identity_pools.connect_api_endpoint
}

# API Key deployment specific outputs
output "devops_service_account_id" {
  description = "DevOps service account ID"
  value       = confluent_service_account.devops_sa.id
}

output "demo_topic_name" {
  description = "Demo topic name"
  value       = confluent_kafka_topic.demo_topic.topic_name
}

output "authentication_method" {
  description = "Authentication method used by this deployment"
  value       = "API_KEY"
}