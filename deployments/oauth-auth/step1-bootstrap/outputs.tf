output "terraform_pool_id" {
  description = "Identity pool ID for Terraform OAuth authentication"
  value       = confluent_identity_pool.terraform_bootstrap.id
}

output "terraform_principal_id" {
  description = "Principal ID for Terraform OAuth authentication"
  value       = "User:${confluent_identity_pool.terraform_bootstrap.id}"
}

output "environment_id" {
  description = "Environment ID"
  value       = var.environment_id
}

# Configuration values needed for step 2
output "step2_configuration" {
  description = "Configuration values needed for step 2 OAuth deployment"
  value = {
    terraform_pool_id           = confluent_identity_pool.terraform_bootstrap.id
    environment_id              = var.environment_id
    existing_identity_provider_id = var.existing_identity_provider_id
    oauth_external_client_id    = var.oauth_external_client_id
  }
  sensitive = false
}