# Azure Applications for Confluent Cloud OAuth

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# Get current Azure AD tenant
data "azuread_client_config" "current" {}

# Application for Terraform Provider Authentication
resource "azuread_application" "terraform_app" {
  display_name    = "az_connect_demo-Confluent-Terraform-OAuth"
  description     = "Azure AD application for Confluent Terraform provider OAuth authentication"
  identifier_uris = ["api://5b6f2fa6-b55f-4189-b2d8-d5acde91b2d8"]
  
  api {
    requested_access_token_version = 2
    
    oauth2_permission_scope {
      admin_consent_description  = "Allow access to Confluent Cloud resources via STS"
      admin_consent_display_name = "Confluent Cloud STS Access"
      enabled                    = true
      id                         = "12345678-1234-5678-9abc-def012345678"
      type                       = "Admin"
      user_consent_description   = "Allow access to Confluent Cloud on your behalf"
      user_consent_display_name  = "Confluent Cloud Access"
      value                      = "confluent.access"
    }
  }
  
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_application_password" "terraform_app_secret" {
  application_id    = azuread_application.terraform_app.id
  display_name      = "az_connect_demo-Terraform OAuth Secret"
  end_date_relative = "8760h" # 1 year
}

# Application for Connector Operations (optional - only if using separate apps)
resource "azuread_application" "connector_app" {
  count = var.create_separate_connector_app ? 1 : 0
  
  display_name = "az_connect_demo-Confluent-Connector-Provisioner"
  description  = "Azure AD application for Confluent connector provisioning operations"
  
  api {
    requested_access_token_version = 2
    
    oauth2_permission_scope {
      admin_consent_description  = "Allow provisioning and management of Confluent Cloud connectors"
      admin_consent_display_name = "Confluent Connector Management"
      enabled                    = true
      id                         = "87654321-4321-8765-dcba-210fedcba987"
      type                       = "Admin"
      user_consent_description   = "Allow connector management on your behalf"
      user_consent_display_name  = "Connector Management"
      value                      = "connectors.manage"
    }
  }
  
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

# Separate identifier URI resource for connector app to avoid circular dependency
resource "azuread_application_identifier_uri" "connector_app_uri" {
  count = var.create_separate_connector_app ? 1 : 0
  
  application_id = azuread_application.connector_app[0].id
  identifier_uri = "api://${azuread_application.connector_app[0].client_id}"
}

resource "azuread_application_password" "connector_app_secret" {
  count = var.create_separate_connector_app ? 1 : 0
  
  application_id    = azuread_application.connector_app[0].id
  display_name      = "az_connect_demo-Connector OAuth Secret"
  end_date_relative = "8760h" # 1 year
}

# Service Principal for Terraform App
resource "azuread_service_principal" "terraform_sp" {
  client_id = azuread_application.terraform_app.client_id
}

# Service Principal for Connector App (if separate)
resource "azuread_service_principal" "connector_sp" {
  count = var.create_separate_connector_app ? 1 : 0
  
  client_id = azuread_application.connector_app[0].client_id
}