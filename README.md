# Confluent Cloud OAuth Authentication with Azure AD

This repository implements OAuth-based authentication for Confluent Cloud using Azure AD identity providers and workload identity pools.

## Azure Application Setup

Azure AD applications are created automatically by Terraform:

### 1. Create Azure Applications

```sh
cd azure-apps
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
terraform init
terraform apply
```

#### Applications

- Terraform Infrastructure Application ([azure-apps/main.tf:16](azure-apps/main.tf#L16))
- Connector Management Application ([azure-apps/main.tf:53](azure-apps/main.tf#L53)) (optional)

#### Outputs

- `terraform_app_client_id`: Used in OAuth deployment steps
- `terraform_app_client_secret`: Used for Terraform provider authentication
- `connector_app_client_id`: Used for connector management (if separate app created)

## OAuth Deployment

### Step 1: Bootstrap Oauth ID Pool and Role-binding

Creates the initial Terraform identity pool using API key authentication. Here we still need Confluent Cloud secrets (chicken-and-egg issue). 

```sh
cd deployments/oauth-auth/step1-bootstrap
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
terraform init
terraform apply
```

#### Resources Created

- Identity pool for Terraform operations ([main.tf:19](deployments/oauth-auth/step1-bootstrap/main.tf#L19))
- `EnvironmentAdmin` role binding for infrastructure management ([main.tf:31](deployments/oauth-auth/step1-bootstrap/main.tf#L31))

### Step 2: Provision Infrastructure

Deploys the main infrastructure using OAuth authentication from step 1.

```sh
cd deployments/oauth-auth/step2-oauth
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
terraform init
terraform apply
```

#### Key Resources Created:

- Kafka cluster ([main.tf:17](deployments/oauth-auth/step2-oauth/main.tf#L17))
- Connector manager identity pool ([modules/confluent-identity-pools/main.tf:7](modules/confluent-identity-pools/main.tf#L7))
- Service account for connector authentication ([main.tf:54](deployments/oauth-auth/step2-oauth/main.tf#L54))
- DataGen connector with ACLs ([main.tf:121](deployments/oauth-auth/step2-oauth/main.tf#L121))

## Connector Management via REST API

### Authentication Flow

1. **Azure AD Token**: Obtain client credentials token from Azure AD
2. **Token Exchange**: Exchange Azure token for Confluent token via STS
3. **API Operations**: Use Confluent token for Connect REST API calls

### Get Azure AD Token

```sh
curl -X POST https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=<connector-app-id>&client_secret=<secret>&scope=api://<connector-app-id>/.default"
```

### Exchange for Confluent Token

```sh
curl -X POST https://api.confluent.cloud/sts/v1/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&subject_token=<azure-token>&subject_token_type=urn:ietf:params:oauth:token-type:access_token&identity_pool_id=<connector-manager-pool-id>"
```

### Connector Operations

```sh
# Resume connector
curl -X PUT https://api.confluent.cloud/connect/v1/environments/<env-id>/clusters/<cluster-id>/connectors/<connector-name>/resume \
  -H "Authorization: Bearer <confluent-token>"

# Pause connector  
curl -X PUT https://api.confluent.cloud/connect/v1/environments/<env-id>/clusters/<cluster-id>/connectors/<connector-name>/pause \
  -H "Authorization: Bearer <confluent-token>"

# Check status
curl -X GET https://api.confluent.cloud/connect/v1/environments/<env-id>/clusters/<cluster-id>/connectors/<connector-name>/status \
  -H "Authorization: Bearer <confluent-token>"
```

## Identity Pool Configuration

### Terraform Bootstrap Pool

- **Purpose**: Infrastructure provisioning via Terraform
- **Filter**: `claims.azp == "<terraform-app-id>"` ([step1-bootstrap/main.tf:27](deployments/oauth-auth/step1-bootstrap/main.tf#L27))
- **Permissions**: EnvironmentAdmin

### Connector Manager Pool  

- **Purpose**: Connector lifecycle management
- **Filter**: `claims.azp == "<connector-app-id>"` ([modules/confluent-identity-pools/main.tf:15](modules/confluent-identity-pools/main.tf#L15))
- **Permissions**: ConnectManager ([modules/confluent-identity-pools/main.tf:50](modules/confluent-identity-pools/main.tf#L50))

## Security Considerations

- Identity pools use application-specific filters to restrict access
- Connector uses service account authentication with minimal ACLs
- Terraform state contains sensitive information and should be secured
- OAuth tokens have limited lifetimes and should be refreshed as needed

## References

- [Confluent Cloud OAuth Documentation](https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/identity-providers/oauth/)
- [Azure AD OAuth 2.0 Client Credentials Flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow)
- [Confluent Connect REST API](https://docs.confluent.io/cloud/current/api.html#tag/Connectors)