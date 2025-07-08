# Step 2: OAuth Authentication Setup
# This deployment uses OAuth tokens for Terraform provider authentication
# using the identity pool created in step 1

# OAuth Provider configuration using bootstrap-created pool
provider "confluent" {
  oauth {
    oauth_external_token_url      = var.oauth_external_token_url
    oauth_external_client_id      = var.oauth_external_client_id
    oauth_external_client_secret  = var.oauth_external_client_secret
    oauth_external_token_scope    = var.oauth_external_token_scope
    oauth_identity_pool_id        = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
  }
}

# Use the shared module for core identity pool and cluster setup
# Note: create_terraform_pool = false since we use the one from step 1
module "confluent_identity_pools" {
  source = "../../../modules/confluent-identity-pools"
  
  # Core configuration
  identity_provider_id = var.existing_identity_provider_id
  environment_id       = var.environment_id
  azure_app_client_id  = var.use_separate_connector_app ? var.azure_app_client_id : var.oauth_external_client_id
  terraform_client_id  = var.oauth_external_client_id
  
  # Cluster configuration
  cluster_name = "az-connect-cluster-oauth"
  cloud        = "AZURE"
  region       = "germanywestcentral"
  
  # Identity pool configuration
  provisioning_pool_name        = "Azure-Connector-Provisioning-Pool-OAuth"
  provisioning_pool_description = "Identity pool for Azure application connector operations (OAuth deployment)"
  terraform_pool_name           = "Terraform-Infrastructure-Pool-OAuth"
  
  # Features - EXCLUDE Terraform pool creation (already created in step 1)
  create_terraform_pool = false
  create_demo_topic     = false  # Will create separately for OAuth compatibility
}

# Demo Topic - No credentials needed with OAuth provider authentication
resource "confluent_kafka_topic" "demo_topic" {
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }
  
  topic_name       = "connector-demo-topic-oauth"
  partitions_count = 3
  rest_endpoint    = module.confluent_identity_pools.cluster_rest_endpoint
  
  # No credentials block needed - OAuth provider handles authentication
  # Ensure module resources are created first
  depends_on = [module.confluent_identity_pools]
}