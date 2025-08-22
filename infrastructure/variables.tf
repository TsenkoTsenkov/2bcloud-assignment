variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing resource group to use"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container for Terraform state"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
}

variable "vm_size" {
  description = "Size of the VMs in the node pool"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "temporary_name_for_rotation" {
  description = "Temporary name for node pool rotation"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}
