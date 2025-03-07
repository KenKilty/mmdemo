# This infrastructure is based on the Azure Verified Module (AVM) pattern for AKS dev/test environments
# Source: https://github.com/Azure/terraform-azurerm-avm-ptn-aks-dev
#
# The infrastructure supports a pragmatic "just enough" approach to modernizing a legacy Java web application
# through containerization. The application, originally running on a VM with direct filesystem access and
# local caching, has been modernized to run in containers while preserving its core architecture. Key changes
# include:
# - Migration from file-based storage to PostgreSQL
# - Container-native configuration and logging
# - Health monitoring and checks
# - Stateless design for horizontal scaling
#
# The infrastructure includes:
# - AKS cluster for running the containerized application
# - ACR for storing the container images
# - RBAC configuration for secure access to resources
# - System-assigned managed identity for AKS to pull from ACR

# Get current user information for RBAC assignments
data "azurerm_client_config" "current" {}

# Create the resource group
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Azure Container Registry
resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location           = azurerm_resource_group.this.location
  sku                = "Premium"
  admin_enabled      = true
  tags               = var.tags
}

# Create AKS cluster
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix         = var.cluster_name
  kubernetes_version = var.kubernetes_version
  tags              = var.tags

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
    
    # Enable system and user pods to run on the same nodes
    only_critical_addons_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  # Use Kubernetes RBAC only
  local_account_disabled = false
}

# Wait for AKS cluster to be fully provisioned
resource "null_resource" "wait_for_aks" {
  depends_on = [azurerm_kubernetes_cluster.this]
  
  provisioner "local-exec" {
    command = <<EOT
      max_retries=10
      retries=0
      while [ "$(az aks show --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name} --query "provisioningState" -o tsv)" != "Succeeded" ]; do
        if [ $retries -ge $max_retries ]; then
          echo "Max retries exceeded. Exiting..."
          exit 1
        fi
        echo "Waiting for AKS cluster to be fully provisioned... (Attempt: $((retries+1)))"
        retries=$((retries+1))
        sleep 30
      done
    EOT
  }
}

# RBAC Assignments
# Grant current user push access to ACR
resource "azurerm_role_assignment" "user_acr_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant AKS cluster pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                           = azurerm_container_registry.this.id
  skip_service_principal_aad_check = true
} 