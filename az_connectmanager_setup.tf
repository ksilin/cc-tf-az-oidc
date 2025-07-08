# Azure Application -> Confluent Cloud Connector Provisioning Setup

# Identity Pool for Azure Application
resource "confluent_identity_pool" "azure_connect_provisioner" {
  identity_provider {
    id = var.existing_identity_provider_id
  }
  
  display_name   = "Azure-Connector-Provisioner-Pool"
  description    = "Identity pool for Azure application to provision Confluent Cloud connectors"
  identity_claim = "claims.sub"
  # TODO - proper claims
  filter         = "has(claims.sup)" #"claims.azp == '${var.azure_app_client_id}'"
}

# re-using existing env here - create new one if needed: 
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_environment
data "confluent_environment" "az_connect_demo" {
  id = "env-nvv5xz"
}


resource "confluent_kafka_cluster" "az_connect_cluster" {
  display_name = "az-connect-cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AZURE"
  region       = "germanywestcentral"
  
  standard {} # needs to be at least standard for RBAC
  
  environment {
    id = data.confluent_environment.az_connect_demo.id
  }
}

# RBAC 

# CloudClusterAdmin - for pool user - required for connector creation
# CAN be transferred to a separate DevOps service account, if we want our pool user to only manage but not create connectors 
resource "confluent_role_binding" "azure_app_cluster_admin" {
  principal   = "User:${confluent_identity_pool.azure_connect_provisioner.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.az_connect_cluster.rbac_crn
}

# ConnectManager - For connector operations (all connectors in first iteration)
# TODO - scoping this to specific connectors
resource "confluent_role_binding" "azure_app_connect_manager" {
  principal   = "User:${confluent_identity_pool.azure_connect_provisioner.id}"
  role_name   = "ConnectManager"
  crn_pattern = "${confluent_kafka_cluster.az_connect_cluster.rbac_crn}/connector=*"
}

# DeveloperWrite - For topics that connectors will write to
resource "confluent_role_binding" "azure_app_topic_write" {
  principal   = "User:${confluent_identity_pool.azure_connect_provisioner.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.az_connect_cluster.rbac_crn}/kafka=${confluent_kafka_cluster.az_connect_cluster.id}/topic=connector-*"
}

# DevOps Service Account - CloudClusterAdmin for topic creation
resource "confluent_role_binding" "devops_sa_cluster_admin" {
  principal   = "User:${confluent_service_account.az_connect_devops_sa.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.az_connect_cluster.rbac_crn
}

# Service Account for DevOps operations - can be reused
resource "confluent_service_account" "az_connect_devops_sa" {
  display_name = "ksi-devops-sa"
  description  = "Service account for infrastructure management - ksi"
}

# API Key for DevOps service account (for infrastructure management)
resource "confluent_api_key" "az-connect-demo-devops_cluster_key" {
  display_name = "az-connect-demo-devops-cluster-key"
  description  = "API key for infrastructure operations"
  
  owner {
    id          = confluent_service_account.az_connect_devops_sa.id
    api_version = "iam/v2"
    kind        = "ServiceAccount"
  }
  
  managed_resource {
    id          = confluent_kafka_cluster.az_connect_cluster.id
    api_version = confluent_kafka_cluster.az_connect_cluster.api_version
    kind        = confluent_kafka_cluster.az_connect_cluster.kind
    
    environment {
      id = data.confluent_environment.az_connect_demo.id
    }
  }
}

# jsut a sample topic for connect testing
resource "confluent_kafka_topic" "demo_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.az_connect_cluster.id
  }
  
  topic_name       = "connector-demo-topic"
  partitions_count = 3
  
  rest_endpoint = confluent_kafka_cluster.az_connect_cluster.rest_endpoint
  
  credentials {
    key    = confluent_api_key.az-connect-demo-devops_cluster_key.id
    secret = confluent_api_key.az-connect-demo-devops_cluster_key.secret
  }
  
  # role binding has to be created before topic creation
  depends_on = [confluent_role_binding.devops_sa_cluster_admin]
}

# Outputs
output "azure_app_principal_id" {
  description = "Principal ID for Azure application (for verification)"
  value       = "User:${confluent_identity_pool.azure_connect_provisioner.id}"
}

output "environment_id" {
  description = "Environment ID for connector provisioning"
  value       = data.confluent_environment.az_connect_demo.id
}

output "cluster_id" {
  description = "Kafka cluster ID for connector provisioning"
  value       = confluent_kafka_cluster.az_connect_cluster.id
}

output "cluster_rest_endpoint" {
  description = "Kafka cluster REST endpoint"
  value       = confluent_kafka_cluster.az_connect_cluster.rest_endpoint
}

output "api_endpoints" {
  description = "Key API endpoints for connector management"
  value = {
    connectors = "https://api.confluent.cloud/connect/v1/environments/${data.confluent_environment.az_connect_demo.id}/clusters/${confluent_kafka_cluster.az_connect_cluster.id}/connectors"
    environments = "https://api.confluent.cloud/org/v2/environments"
    clusters = "https://api.confluent.cloud/cmk/v2/clusters"
  }
}