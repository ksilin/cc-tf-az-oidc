# Terraform App Outputs
output "terraform_client_id" {
  description = "Client ID for Terraform OAuth authentication"
  value       = azuread_application.terraform_app.client_id
}

output "terraform_client_secret" {
  description = "Client secret for Terraform OAuth authentication"
  value       = azuread_application_password.terraform_app_secret.value
  sensitive   = true
}

output "terraform_object_id" {
  description = "Object ID of Terraform application"
  value       = azuread_application.terraform_app.object_id
}

# Connector App Outputs (if created)
output "connector_client_id" {
  description = "Client ID for connector operations"
  value       = var.create_separate_connector_app ? azuread_application.connector_app[0].client_id : azuread_application.terraform_app.client_id
}

output "connector_client_secret" {
  description = "Client secret for connector operations"
  value       = var.create_separate_connector_app ? azuread_application_password.connector_app_secret[0].value : azuread_application_password.terraform_app_secret.value
  sensitive   = true
}

# Tenant Information
output "tenant_id" {
  description = "Azure AD tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

output "oauth_token_url" {
  description = "OAuth token endpoint URL"
  value       = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token"
}

# Ready-to-use values for Confluent deployment
output "confluent_oauth_config" {
  description = "Values to use in Confluent OAuth deployment"
  value = {
    oauth_external_token_url     = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token"
    oauth_external_client_id     = azuread_application.terraform_app.client_id
    oauth_external_client_secret = azuread_application_password.terraform_app_secret.value
    azure_app_client_id          = var.create_separate_connector_app ? azuread_application.connector_app[0].client_id : azuread_application.terraform_app.client_id
    use_separate_connector_app   = var.create_separate_connector_app
    
    # New scope information
    terraform_scope              = "api://${azuread_application.terraform_app.client_id}/confluent.access"
    connector_scope              = var.create_separate_connector_app ? "api://${azuread_application.connector_app[0].client_id}/connectors.manage" : "api://${azuread_application.terraform_app.client_id}/confluent.access"
  }
  sensitive = true
}

# API scope information for testing
output "api_scopes" {
  description = "API scopes for token requests"
  value = {
    terraform_api_scope = "api://${azuread_application.terraform_app.client_id}/confluent.access"
    connector_api_scope = var.create_separate_connector_app ? "api://${azuread_application.connector_app[0].client_id}/connectors.manage" : "api://${azuread_application.terraform_app.client_id}/confluent.access"
  }
}