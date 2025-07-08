# Step 1: Bootstrap Phase - Create Terraform Identity Pool with API Keys
# This phase creates the identity pool needed for OAuth provider authentication

# API Key Provider (temporary for bootstrap)
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Get environment data
data "confluent_environment" "main" {
  id = var.environment_id
}

# Get organization data for CRN pattern
data "confluent_organization" "main" {}

# Create ONLY the Terraform identity pool for OAuth authentication
resource "confluent_identity_pool" "terraform_bootstrap" {
  identity_provider {
    id = var.existing_identity_provider_id
  }
  
  display_name   = "Terraform-Infrastructure-Pool-OAuth-Bootstrap"
  description    = "Bootstrap identity pool for Terraform OAuth authentication"
  identity_claim = "claims.sub"
  filter         = "has(claims.sub)"
}

# Environment admin role for Terraform pool
resource "confluent_role_binding" "terraform_environment_admin" {
  principal   = "User:${confluent_identity_pool.terraform_bootstrap.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = data.confluent_environment.main.resource_name
}