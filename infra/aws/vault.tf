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

provider "vault" {
}

provider "kubernetes" {
  host                   = aws_eks_cluster.insecure_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.insecure_eks.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.insecure_eks.name]
    command     = "aws"
  }
}


data "vault_generic_secret" "db_credentials" {
  path = "secret/data/devsecops/database"
}

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

  depends_on = [
    aws_eks_cluster.insecure_eks
  ]
}
