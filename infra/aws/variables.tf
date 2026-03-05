variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "insecure-cluster"
}

variable "db_username" {
  description = "Database username for Kubernetes secret"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password for Kubernetes secret"
  type        = string
  sensitive   = true
}

variable "enable_account_access_analyzer" {
  description = "Whether to create an account-level IAM Access Analyzer (may fail if quota is already used)"
  type        = bool
  default     = false
}
