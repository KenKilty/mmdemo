variable "resource_group_name" {
  description = "Name of the resource group to create resources in"
  type        = string
  default     = "migration-draft-rg"
}

variable "location" {
  description = "Azure region to deploy resources in"
  type        = string
  default     = "westus3"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "migration-draft-aks"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "migrationdraftacr"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "Size of the node pool VMs"
  type        = string
  default     = "Standard_D4_v3"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Migration Draft"
    Purpose     = "Legacy Java App Containerization"
    Stage       = "Kubernetes Deployment"
    Terraform   = "true"
  }
} 