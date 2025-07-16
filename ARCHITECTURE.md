# Architecture Diagrams

## Component/Resource Diagram

```mermaid
graph TB
    subgraph "Azure AD Tenant"
        TF_APP["Terraform App<br/>5b6f2fa6-b55f-4189-b2d8-d5acde91b2d8"]
        CONN_APP["Connector App<br/>a61d8aa0-7023-468c-9107-c4a8aec823be"]
    end
    
    subgraph "Confluent Cloud"
        subgraph "Identity Provider"
            IDP["Azure AD Identity Provider<br/>op-4N"]
        end
        
        subgraph "Environment: env-nvv5xz"
            subgraph "Identity Pools"
                TF_POOL["Terraform Bootstrap Pool<br/>pool-k0MbP<br/>Principal: User:pool-k0MbP"]
                CONN_POOL["Connector Manager Pool<br/>pool-Rknrq<br/>Principal: User:pool-Rknrq"]
            end
            
            subgraph "Kafka Cluster: lkc-wm3y09"
                CLUSTER["Kafka Cluster<br/>az-connect-cluster-oauth"]
                TOPIC["Topic<br/>connector-target-topic-oauth"]
                SA["Service Account<br/>sa-gqn7mv3"]
                CONNECTOR["DataGen Connector<br/>lcc-y8vmwo"]
            end
            
            subgraph "RBAC Permissions"
                ENV_ADMIN["EnvironmentAdmin<br/>→ User:pool-k0MbP"]
                CONN_MGR["ConnectManager<br/>→ User:pool-Rknrq"]
                TOPIC_ACLS["Topic ACLs<br/>→ User:sa-gqn7mv3"]
            end
        end
    end
    
    subgraph "Terraform Operations"
        TF_STEP1["Step 1: Bootstrap<br/>API Key Auth"]
        TF_STEP2["Step 2: OAuth Infrastructure<br/>OAuth Auth"]
    end
    
    subgraph "REST API Operations"
        CONN_OPS["Connector Operations<br/>Pause/Resume/Status"]
    end
    
    %% Relationships
    TF_APP --> TF_POOL
    CONN_APP --> CONN_POOL
    TF_POOL --> ENV_ADMIN
    CONN_POOL --> CONN_MGR
    SA --> TOPIC_ACLS
    
    TF_STEP1 --> TF_POOL
    TF_STEP2 --> CLUSTER
    TF_STEP2 --> CONN_POOL
    TF_STEP2 --> SA
    TF_STEP2 --> CONNECTOR
    
    CONN_OPS --> CONNECTOR
    
    %% Filters
    TF_POOL -.->|"Filter: claims.azp == 5b6f2fa6..."| TF_APP
    CONN_POOL -.->|"Filter: claims.azp == a61d8aa0..."| CONN_APP
    
    %% Authentication
    CONNECTOR -.->|"kafka.service.account.id"| SA
    
    classDef azureApp fill:#0078d4,stroke:#005a9e,stroke-width:2px,color:#fff
    classDef identityPool fill:#ff6b35,stroke:#e55a2b,stroke-width:2px,color:#fff
    classDef kafkaResource fill:#2ecc71,stroke:#27ae60,stroke-width:2px,color:#fff
    classDef rbacRole fill:#9b59b6,stroke:#8e44ad,stroke-width:2px,color:#fff
    classDef operation fill:#f39c12,stroke:#e67e22,stroke-width:2px,color:#fff
    
    class TF_APP,CONN_APP azureApp
    class TF_POOL,CONN_POOL identityPool
    class CLUSTER,TOPIC,SA,CONNECTOR kafkaResource
    class ENV_ADMIN,CONN_MGR,TOPIC_ACLS rbacRole
    class TF_STEP1,TF_STEP2,CONN_OPS operation
```

## Interaction Diagram - OAuth Authentication Flow

```mermaid
sequenceDiagram
    participant Client as Client Application
    participant AzureAD as Azure AD Tenant
    participant STS as Confluent STS
    participant Pool as Identity Pool
    participant API as Confluent API
    participant Connector as Kafka Connector
    
    Note over Client,Connector: Phase 1: Authentication
    
    Client->>+AzureAD: POST /oauth2/v2.0/token<br/>grant_type=client_credentials<br/>client_id=a61d8aa0-7023-468c-9107-c4a8aec823be<br/>scope=api://a61d8aa0-7023-468c-9107-c4a8aec823be/.default
    AzureAD-->>-Client: Azure AD Token<br/>Principal: Application a61d8aa0-7023-468c-9107-c4a8aec823be
    
    Client->>+STS: POST /sts/v1/oauth2/token<br/>grant_type=urn:ietf:params:oauth:grant-type:token-exchange<br/>subject_token=<azure_token><br/>identity_pool_id=pool-Rknrq
    
    STS->>+Pool: Validate Token & Filter<br/>claims.azp == "a61d8aa0-7023-468c-9107-c4a8aec823be"
    Pool-->>-STS: ✓ Valid, Principal: User:pool-Rknrq
    
    STS-->>-Client: Confluent Token<br/>Principal: User:pool-Rknrq
    
    Note over Client,Connector: Phase 2: Authorization & Operations
    
    Client->>+API: PUT /connect/v1/environments/env-nvv5xz/clusters/lkc-wm3y09/connectors/datagen-oauth-sa-demo/resume<br/>Authorization: Bearer <confluent_token>
    
    API->>API: Check RBAC<br/>Principal: User:pool-Rknrq<br/>Role: ConnectManager<br/>Resource: connector=*
    
    API->>+Connector: Resume Operation<br/>Auth Mode: SERVICE_ACCOUNT<br/>Service Account: sa-gqn7mv3
    
    Connector->>Connector: Check Topic ACLs<br/>Principal: User:sa-gqn7mv3<br/>Operations: WRITE, DESCRIBE
    
    Connector-->>-API: ✓ Connector Resumed
    API-->>-Client: 200 OK
    
    Note over Client,Connector: Phase 3: Status Check
    
    Client->>+API: GET /connect/v1/environments/env-nvv5xz/clusters/lkc-wm3y09/connectors/datagen-oauth-sa-demo/status<br/>Authorization: Bearer <confluent_token>
    
    API->>API: Check RBAC<br/>Principal: User:pool-Rknrq<br/>Role: ConnectManager
    
    API-->>-Client: 200 OK<br/>{"connector": {"state": "RUNNING"}}
```

## Two-Phase Terraform Deployment Flow

```mermaid
sequenceDiagram
    participant Admin as Administrator
    participant Azure as Azure AD
    participant Step1 as Step 1 Bootstrap
    participant CC_API as Confluent API (API Key)
    participant CC_OAuth as Confluent API (OAuth)
    participant Step2 as Step 2 Infrastructure
    participant Resources as Confluent Resources
    
    Note over Admin,Resources: Phase 0: Azure Setup
    
    Admin->>+Azure: terraform apply (azure-apps)
    Azure-->>-Admin: Created Applications:<br/>- Terraform: 5b6f2fa6-b55f-4189-b2d8-d5acde91b2d8<br/>- Connector: a61d8aa0-7023-468c-9107-c4a8aec823be
    
    Note over Admin,Resources: Phase 1: Bootstrap (API Key Auth)
    
    Admin->>+Step1: terraform apply<br/>Provider: API Key Auth
    Step1->>+CC_API: Create Identity Pool<br/>Principal: API Key
    CC_API-->>-Step1: pool-k0MbP created<br/>Filter: claims.azp == "5b6f2fa6..."
    
    Step1->>+CC_API: Create Role Binding<br/>Principal: API Key
    CC_API-->>-Step1: EnvironmentAdmin → User:pool-k0MbP
    
    Step1-->>-Admin: Bootstrap Complete<br/>Terraform Pool: pool-k0MbP
    
    Note over Admin,Resources: Phase 2: Infrastructure (OAuth Auth)
    
    Admin->>+Step2: terraform apply<br/>Provider: OAuth (pool-k0MbP)
    
    Step2->>+Azure: Get OAuth Token<br/>client_id=5b6f2fa6-b55f-4189-b2d8-d5acde91b2d8
    Azure-->>-Step2: Azure AD Token
    
    Step2->>+CC_OAuth: Exchange Token<br/>identity_pool_id=pool-k0MbP
    CC_OAuth-->>-Step2: Confluent Token<br/>Principal: User:pool-k0MbP
    
    Step2->>+Resources: Create Kafka Cluster<br/>Principal: User:pool-k0MbP (EnvironmentAdmin)
    Resources-->>-Step2: lkc-wm3y09 created
    
    Step2->>+Resources: Create Connector Pool<br/>Principal: User:pool-k0MbP (EnvironmentAdmin)
    Resources-->>-Step2: pool-Rknrq created<br/>Filter: claims.azp == "a61d8aa0..."
    
    Step2->>+Resources: Create Service Account<br/>Principal: User:pool-k0MbP (EnvironmentAdmin)
    Resources-->>-Step2: sa-gqn7mv3 created
    
    Step2->>+Resources: Create Connector<br/>Principal: User:pool-k0MbP (EnvironmentAdmin)
    Resources-->>-Step2: lcc-y8vmwo created<br/>Auth: SERVICE_ACCOUNT (sa-gqn7mv3)
    
    Step2-->>-Admin: Infrastructure Complete<br/>Connector Manager Pool: pool-Rknrq
```

## Principal Authorization Matrix

| Operation | Principal | Role/Permission | Resource Pattern |
|-----------|-----------|-----------------|------------------|
| **Terraform Bootstrap** | User:pool-k0MbP | EnvironmentAdmin | env-nvv5xz |
| **Connector Management** | User:pool-Rknrq | ConnectManager | connector=* |
| **Topic Operations** | User:sa-gqn7mv3 | Topic ACLs | connector-target-topic-oauth |
| **Cluster Operations** | User:sa-gqn7mv3 | Cluster ACLs | lkc-wm3y09 |
| **Consumer Groups** | User:sa-gqn7mv3 | Group ACLs | connect-* |

## Security Boundaries

```mermaid
graph TB
    subgraph "Azure AD Security Boundary"
        subgraph "Terraform App Scope"
            TF_CLAIMS["Claims Filter:<br/>claims.azp == 5b6f2fa6..."]
        end
        
        subgraph "Connector App Scope"
            CONN_CLAIMS["Claims Filter:<br/>claims.azp == a61d8aa0..."]
        end
    end
    
    subgraph "Confluent Cloud Security Boundary"
        subgraph "Infrastructure Management"
            TF_RBAC["Principal: User:pool-k0MbP<br/>Role: EnvironmentAdmin<br/>Scope: Environment"]
        end
        
        subgraph "Connector Management"
            CONN_RBAC["Principal: User:pool-Rknrq<br/>Role: ConnectManager<br/>Scope: Connectors"]
        end
        
        subgraph "Data Access"
            SA_ACLS["Principal: User:sa-gqn7mv3<br/>ACLs: Topic WRITE/DESCRIBE<br/>Scope: Specific Topic"]
        end
    end
    
    TF_CLAIMS --> TF_RBAC
    CONN_CLAIMS --> CONN_RBAC
    CONN_RBAC --> SA_ACLS
    
    classDef azureSec fill:#0078d4,stroke:#005a9e,stroke-width:3px,color:#fff
    classDef confluentSec fill:#ff6b35,stroke:#e55a2b,stroke-width:3px,color:#fff
    classDef dataSec fill:#2ecc71,stroke:#27ae60,stroke-width:3px,color:#fff
    
    class TF_CLAIMS,CONN_CLAIMS azureSec
    class TF_RBAC,CONN_RBAC confluentSec
    class SA_ACLS dataSec
```