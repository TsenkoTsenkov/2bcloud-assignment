terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "Tsenko-Tsenkov-Candidate"
    storage_account_name = "stterraformstate2bcloud"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                        = "default"
    node_count                  = var.node_count
    vm_size                     = var.vm_size
    temporary_name_for_rotation = var.temporary_name_for_rotation
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  tags = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = var.tags
}

# Attach ACR to AKS cluster for  image pulling
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Create kubernetes namespace for the application
resource "kubernetes_namespace" "nodejs_app" {
  metadata {
    name = "nodejs-app"
    labels = {
      name = "nodejs-app"
      app  = "nodejs-app"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}
