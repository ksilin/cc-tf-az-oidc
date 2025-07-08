# Reference step 1 bootstrap outputs
data "terraform_remote_state" "bootstrap" {
  backend = "local"
  
  config = {
    path = "../step1-bootstrap/terraform.tfstate"
  }
}

# Verify the identity pool exists and is accessible
data "confluent_identity_pool" "terraform_pool" {
  id = data.terraform_remote_state.bootstrap.outputs.terraform_pool_id
  
  identity_provider {
    id = var.existing_identity_provider_id
  }
}