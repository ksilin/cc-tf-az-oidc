# Environment Information
output "environment_id" {
  description = "Environment ID"
  value       = var.environment_id
}

output "environment_resource_name" {
  description = "Environment resource name for RBAC"
  value       = data.confluent_environment.main.resource_name
}

# Cluster Information
output "cluster_id" {
  description = "Kafka cluster ID"
  value       = confluent_kafka_cluster.main.id
}

output "cluster_api_version" {
  description = "Kafka cluster API version"
  value       = confluent_kafka_cluster.main.api_version
}

output "cluster_kind" {
  description = "Kafka cluster kind"
  value       = confluent_kafka_cluster.main.kind
}

output "cluster_rbac_crn" {
  description = "Kafka cluster RBAC CRN"
  value       = confluent_kafka_cluster.main.rbac_crn
}

output "cluster_rest_endpoint" {
  description = "Kafka cluster REST endpoint"
  value       = confluent_kafka_cluster.main.rest_endpoint
}

# Identity Pool Information
output "connector_manager_pool_id" {
  description = "Connector manager identity pool ID"
  value       = confluent_identity_pool.connector_manager.id
}

output "connector_manager_principal_id" {
  description = "Connector manager principal ID for verification"
  value       = "User:${confluent_identity_pool.connector_manager.id}"
}

# Legacy outputs for backward compatibility
output "azure_provisioning_pool_id" {
  description = "[DEPRECATED] Use connector_manager_pool_id instead"
  value       = confluent_identity_pool.connector_manager.id
}

output "azure_provisioning_principal_id" {
  description = "[DEPRECATED] Use connector_manager_principal_id instead"
  value       = "User:${confluent_identity_pool.connector_manager.id}"
}

output "terraform_pool_id" {
  description = "Terraform identity pool ID (if created)"
  value       = var.create_terraform_pool ? confluent_identity_pool.terraform_provisioner[0].id : null
}

output "terraform_principal_id" {
  description = "Terraform principal ID (if created)"
  value       = var.create_terraform_pool ? "User:${confluent_identity_pool.terraform_provisioner[0].id}" : null
}


# Connect API Endpoint
output "connect_api_endpoint" {
  description = "API endpoint for connector management"
  value = {
    connectors   = "https://api.confluent.cloud/connect/v1/environments/${var.environment_id}/clusters/${confluent_kafka_cluster.main.id}/connectors"
  }
}