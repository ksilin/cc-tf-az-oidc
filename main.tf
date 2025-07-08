terraform {
  required_version = ">= 1.0"
  
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.34.0"  # Latest version as of July 2025
    }
  }
}

# Configure the Confluent Provider
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# no identity provider creation here, since using existing
# The identity_pool.tf will reference the existing provider