terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
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

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    username = var.db_username
    password = var.db_password
  }

  depends_on = [
    aws_eks_cluster.insecure_eks
  ]
}
