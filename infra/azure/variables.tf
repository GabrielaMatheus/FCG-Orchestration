variable "azure_subscription_id" {
  description = "Azure subscription that will receive all Fase 4 resources."
  type        = string
}

variable "location" {
  description = "Azure region for AKS and the managed data services."
  type        = string
  default     = "East US 2"
}

variable "project_name" {
  type    = string
  default = "fcg"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "cluster_name" {
  type    = string
  default = "fcg-prod-aks"
}

variable "kubernetes_version" {
  description = "AKS version. Null lets Azure choose a currently supported version."
  type        = string
  default     = null
  nullable    = true
}

variable "node_vm_size" {
  description = "VM size for the academic AKS node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "postgres_sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "redis_sku_name" {
  description = "Azure Managed Redis SKU. Balanced_B0 is the smallest balanced tier."
  type        = string
  default     = "Balanced_B0"
}

variable "redis_high_availability_enabled" {
  description = "Enable Redis replication. False reduces the cost of the short-lived academic environment."
  type        = bool
  default     = false
}

variable "cosmos_enable_free_tier" {
  description = "Azure permits only one Cosmos DB free-tier account per subscription. Set false if one already exists."
  type        = bool
  default     = true
}

variable "elastic_cloud_api_key" {
  description = "Elastic Cloud organization API key. Supply with TF_VAR_elastic_cloud_api_key."
  type        = string
  sensitive   = true
}

variable "elastic_region" {
  description = "Elastic Cloud region hosted on Microsoft Azure."
  type        = string
  default     = "azure-eastus2"
}

variable "elastic_deployment_template" {
  type    = string
  default = "azure-general-purpose"
}

variable "rabbitmq_username" {
  type    = string
  default = "fcg-runtime"
}

variable "admin_email" {
  type = string
}

variable "github_owner" {
  type    = string
  default = "GabrielaMatheus"
}

variable "github_repositories" {
  type    = list(string)
  default = ["FCG-UsersAPI", "FCG-CatalogAPI"]
}
