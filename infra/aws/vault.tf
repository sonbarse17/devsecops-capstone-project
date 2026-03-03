terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

# ---------------------------------------------------------
# Vault Provider Configuration
# ---------------------------------------------------------
# In a real environment, you would use environment variables:
# export VAULT_ADDR="https://vault.your-domain.com:8200"
# export VAULT_TOKEN="s.xyz123abc..."
# Or use Vault AppRole / AWS IAM auth methods for Terraform.
provider "vault" {
  # address = "http://127.0.0.1:8200"
  # skip_tls_verify = true
}

# ---------------------------------------------------------
# Kubernetes Provider Configuration
# ---------------------------------------------------------
provider "kubernetes" {
  host                   = aws_eks_cluster.insecure_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.insecure_eks.certificate_authority[0].data)

  # Ensure you map the AWS auth correctly to EKS
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.insecure_eks.name]
    command     = "aws"
  }
}

# ---------------------------------------------------------
# HashiCorp Vault Data Sources & Kubernetes Secrets
# ---------------------------------------------------------

# Read secrets from HashiCorp Vault
# We assume the secret engine is KV2 and mounted at 'secret'
# with the secrets stored under the path 'devsecops/database'
data "vault_generic_secret" "db_credentials" {
  path = "secret/data/devsecops/database"
}

# Dynamically provision the Kubernetes Secret during Terraform apply
# so that the secret never touches disk in plaintext / git repo!
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    username = data.vault_generic_secret.db_credentials.data["username"]
    password = data.vault_generic_secret.db_credentials.data["password"]
  }

  # Ensure the cluster exists first
  depends_on = [
    aws_eks_cluster.insecure_eks
  ]
}
