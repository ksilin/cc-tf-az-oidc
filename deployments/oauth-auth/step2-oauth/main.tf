# Step 2: OAuth Setup
# This deployment uses OAuth tokens for Terraform provider authentication
# using the identity pool created in step 1
# BUT - this does not cover the connectivity between the connector and the cluster

provider "confluent" {
  oauth {
    oauth_external_token_url      = var.oauth_external_token_url
    oauth_external_client_id      = var.oauth_external_client_id
    oauth_external_client_secret  = var.oauth_external_client_secret
    oauth_external_token_scope    = var.oauth_external_token_scope
    oauth_identity_pool_id        = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
  }
}

# create_terraform_pool = false since we use the one from step 1
module "confluent_identity_pools" {
  source = "../../../modules/confluent-identity-pools"
  
  identity_provider_id = var.existing_identity_provider_id
  environment_id       = var.environment_id
  azure_app_client_id  = var.use_separate_connector_app ? var.azure_app_client_id : var.oauth_external_client_id
  terraform_client_id  = var.oauth_external_client_id
  
  cluster_name = "az-connect-cluster-oauth"
  cloud        = "AZURE"
  region       = "germanywestcentral"
  
  # Identity pool configuration
  connector_manager_pool_name        = "Azure-Connector-Manager-Pool-OAuth"
  connector_manager_pool_description = "Identity pool for Azure application connector management (OAuth deployment)"
  terraform_pool_name           = "Terraform-Infrastructure-Pool-OAuth"
  
  # pool from step 1
  create_terraform_pool = false
}

# Connector Target Topic - No credentials needed with OAuth provider authentication
resource "confluent_kafka_topic" "connector_target_topic" {
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }

  # no credentials block needed with OAuth
  
  topic_name       = "connector-target-topic-oauth"
  partitions_count = 3
  rest_endpoint    = module.confluent_identity_pools.cluster_rest_endpoint
  
  depends_on = [module.confluent_identity_pools]
}

# Service Account for DataGen Connector
resource "confluent_service_account" "datagen_connector_sa" {
  display_name = "datagen-connector-sa-oauth"
  description  = "Service account for DataGen connector with minimal ACL permissions"
}

# Topic ACLs - Write permission
resource "confluent_kafka_acl" "connector_topic_write" {
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.connector_target_topic.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.datagen_connector_sa.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = module.confluent_identity_pools.cluster_rest_endpoint
}

# Topic ACLs - Describe permission
resource "confluent_kafka_acl" "connector_topic_describe" {
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.connector_target_topic.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.datagen_connector_sa.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = module.confluent_identity_pools.cluster_rest_endpoint
}


# Consumer Group ACLs - Read permission for connector coordination
resource "confluent_kafka_acl" "connector_consumer_group_read" {
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }
  resource_type = "GROUP"
  resource_name = "connect-"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.datagen_connector_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = module.confluent_identity_pools.cluster_rest_endpoint
}

# Cluster ACLs - Describe permission
resource "confluent_kafka_acl" "connector_cluster_describe" {
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.datagen_connector_sa.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = module.confluent_identity_pools.cluster_rest_endpoint
}

# DataGen Source Connector - Using Service Account Authentication
resource "confluent_connector" "datagen_source" {
  environment {
    id = var.environment_id
  }
  kafka_cluster {
    id = module.confluent_identity_pools.cluster_id
  }
  
  config_sensitive = {}
  
  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "datagen-oauth-sa-demo"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.datagen_connector_sa.id
    "kafka.topic"              = confluent_kafka_topic.connector_target_topic.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"              = "USERS"
    "max.interval"            = "1000"
    "iterations"              = "10000000"
    "tasks.max"               = "1"
  }
  
  status = "PAUSED"
  
  depends_on = [
    confluent_kafka_acl.connector_topic_write,
    confluent_kafka_acl.connector_topic_describe,
    confluent_kafka_acl.connector_consumer_group_read,
    confluent_kafka_acl.connector_cluster_describe,
    module.confluent_identity_pools
  ]
}