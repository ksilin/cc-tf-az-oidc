# Traditional API Key Authentication Setup
# This deployment uses Confluent Cloud API keys for Terraform provider authentication

# Provider configuration with API keys
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Use the shared module for core identity pool and cluster setup
module "confluent_identity_pools" {
  source = "../../modules/confluent-identity-pools"
  
  # Core configuration
  identity_provider_id = var.existing_identity_provider_id
  environment_id       = var.environment_id
  azure_app_client_id  = var.azure_app_client_id
  
  # Cluster configuration
  cluster_name = "az-connect-cluster-apikey"
  cloud        = "AZURE"
  region       = "germanywestcentral"
  
  # Identity pool configuration
  provisioning_pool_name        = "Azure-Connector-Provisioning-Pool-APIKey"
  provisioning_pool_description = "Identity pool for Azure application connector operations (API key deployment)"
  
  # Features
  create_terraform_pool = false  # Not needed for API key auth
  create_demo_topic     = false  # Will create separately with credentials
}

# Service Account for DevOps operations (to avoid user API key limits)
resource "confluent_service_account" "devops_sa" {
  display_name = "devops-infrastructure-sa-apikey"
  description  = "Service account for DevOps infrastructure management (API key deployment)"
}

# API Key for DevOps service account
resource "confluent_api_key" "devops_cluster_key" {
  display_name = "devops-cluster-key-apikey"
  description  = "API key for DevOps infrastructure operations (API key deployment)"
  
  owner {
    id          = confluent_service_account.devops_sa.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }
  
  managed_resource {
    id          = module.confluent_identity_pools.cluster_id
    api_version = module.confluent_identity_pools.cluster_api_version
    kind        = module.confluent_identity_pools.cluster_kind
    
    environment {
      id = var.environment_id
    }
  }
}

# DevOps Service Account permissions for infrastructure operations
resource "confluent_role_binding" "devops_sa_cluster_admin" {
  principal   = "User:${confluent_service_account.devops_sa.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = module.confluent_identity_pools.cluster_rbac_crn
}

# Demo Topic with API key credentials
resource "confluent_kafka_topic" "demo_topic" {
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }
  
  topic_name       = "connector-demo-topic"
  partitions_count = 3
  rest_endpoint    = module.confluent_identity_pools.cluster_rest_endpoint
  
  credentials {
    key    = confluent_api_key.devops_cluster_key.id
    secret = confluent_api_key.devops_cluster_key.secret
  }
  
  # Ensure role binding is created before topic creation
  depends_on = [confluent_role_binding.devops_sa_cluster_admin]
}