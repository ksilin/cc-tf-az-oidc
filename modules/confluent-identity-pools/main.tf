# Get environment data
data "confluent_environment" "main" {
  id = var.environment_id
}

# 1. Create Identity Pool for Azure Application (Connector Operations)
resource "confluent_identity_pool" "azure_provisioning" {
  identity_provider {
    id = var.identity_provider_id
  }
  
  display_name   = var.provisioning_pool_name
  description    = var.provisioning_pool_description
  identity_claim = var.identity_claim
  filter         = var.provisioning_filter != null ? var.provisioning_filter : "claims.azp == '${var.azure_app_client_id}'"
}

# 2. Create Identity Pool for Terraform Provider (Optional, for OAuth setup)
resource "confluent_identity_pool" "terraform_provisioner" {
  count = var.create_terraform_pool ? 1 : 0
  
  identity_provider {
    id = var.identity_provider_id
  }
  
  display_name   = var.terraform_pool_name
  description    = "Identity pool for Terraform infrastructure management via OAuth"
  identity_claim = var.identity_claim
  filter         = "claims.azp == '${var.terraform_client_id}'"
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

# 4. RBAC Role Bindings for Azure Application (Connector Operations)

# CloudClusterAdmin - Required for connector creation
resource "confluent_role_binding" "azure_provisioning_cluster_admin" {
  principal   = "User:${confluent_identity_pool.azure_provisioning.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.main.rbac_crn
}

# ConnectManager - For connector management operations (all connectors)
resource "confluent_role_binding" "azure_provisioning_connect_manager" {
  principal   = "User:${confluent_identity_pool.azure_provisioning.id}"
  role_name   = "ConnectManager"
  crn_pattern = "${confluent_kafka_cluster.main.rbac_crn}/connector=*"
}

# DeveloperWrite - For topics that connectors will write to
resource "confluent_role_binding" "azure_provisioning_topic_write" {
  principal   = "User:${confluent_identity_pool.azure_provisioning.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.main.rbac_crn}/kafka=${confluent_kafka_cluster.main.id}/topic=connector-*"
}

# 5. RBAC Role Bindings for Terraform Identity Pool (if enabled)
resource "confluent_role_binding" "terraform_environment_admin" {
  count = var.create_terraform_pool ? 1 : 0
  
  principal   = "User:${confluent_identity_pool.terraform_provisioner[0].id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = data.confluent_environment.main.resource_name
}

# 6. Demo Topic (optional)
resource "confluent_kafka_topic" "demo_topic" {
  count = var.create_demo_topic ? 1 : 0
  
  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }
  
  topic_name       = var.demo_topic_name
  partitions_count = 3
  rest_endpoint    = confluent_kafka_cluster.main.rest_endpoint
  
  # Topic creation will depend on deployment type (API key vs OAuth)
  # Credentials will be handled in the deployment-specific configurations
}