# Get environment data
data "confluent_environment" "main" {
  id = var.environment_id
}

# 1. Create Identity Pool for Azure Application (Connector Management)
resource "confluent_identity_pool" "connector_manager" {
  identity_provider {
    id = var.identity_provider_id
  }
  
  display_name   = var.connector_manager_pool_name != null ? var.connector_manager_pool_name : (var.provisioning_pool_name != null ? var.provisioning_pool_name : "Azure-Connector-Manager-Pool")
  description    = var.connector_manager_pool_description != null ? var.connector_manager_pool_description : (var.provisioning_pool_description != null ? var.provisioning_pool_description : "Identity pool for Azure application to manage Confluent Cloud connectors")
  identity_claim = var.identity_claim
  filter         = var.connector_manager_filter != null ? var.connector_manager_filter : (var.provisioning_filter != null ? var.provisioning_filter : "claims.azp == \"${var.azure_app_client_id}\"")
}

# 2. Create Identity Pool for Terraform Provider (Infrastructure Provisioning)
resource "confluent_identity_pool" "terraform_provisioner" {
  count = var.create_terraform_pool ? 1 : 0
  
  identity_provider {
    id = var.identity_provider_id
  }
  
  display_name   = var.terraform_pool_name
  description    = "Identity pool for Terraform infrastructure management via OAuth"
  identity_claim = var.identity_claim
  filter         = "claims.azp == \"${var.terraform_client_id}\""
}

# 3. Create Kafka Cluster
resource "confluent_kafka_cluster" "main" {
  display_name = var.cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.cloud
  region       = var.region
  
  standard {} # Standard cluster for RBAC support
  
  environment {
    id = var.environment_id
  }
}

# 4. RBAC Role Bindings for Azure Application (Connector Management)


# ConnectManager - For connector management operations (all connectors)
resource "confluent_role_binding" "connector_manager_connect_manager" {
  principal   = "User:${confluent_identity_pool.connector_manager.id}"
  role_name   = "ConnectManager"
  crn_pattern = "${confluent_kafka_cluster.main.rbac_crn}/connector=*"
}


# 5. RBAC Role Bindings for Terraform Identity Pool (Infrastructure Provisioning)
resource "confluent_role_binding" "terraform_environment_admin" {
  count = var.create_terraform_pool ? 1 : 0
  
  principal   = "User:${confluent_identity_pool.terraform_provisioner[0].id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = data.confluent_environment.main.resource_name
}

# NOTE: Topics should be created in specific deployments, not in this module
# This module focuses on identity pools, clusters, and RBAC - not application topics