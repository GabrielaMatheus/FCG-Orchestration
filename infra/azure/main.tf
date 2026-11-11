terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.56, < 5.0"
    }
    ec = {
      source  = "elastic/ec"
      version = "~> 0.13.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {}
}

provider "ec" {
  apikey = var.elastic_cloud_api_key
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  prefix  = "${var.project_name}-${var.environment}"
  compact = lower(replace("${var.project_name}${var.environment}${random_string.suffix.result}", "-", ""))
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Course      = "FIAP-Tech-Challenge-Fase-4"
  }
}

resource "azurerm_resource_group" "fcg" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "fcg" {
  name                = "vnet-${local.prefix}"
  address_space       = ["10.42.0.0/16"]
  location            = azurerm_resource_group.fcg.location
  resource_group_name = azurerm_resource_group.fcg.name
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.fcg.name
  virtual_network_name = azurerm_virtual_network.fcg.name
  address_prefixes     = ["10.42.0.0/20"]
  service_endpoints    = ["Microsoft.AzureCosmosDB", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres"
  resource_group_name  = azurerm_resource_group.fcg.name
  virtual_network_name = azurerm_virtual_network.fcg.name
  address_prefixes     = ["10.42.16.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "postgres-flexible-server"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.fcg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.fcg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.fcg.id
}

resource "azurerm_container_registry" "fcg" {
  name                = "${local.compact}acr"
  resource_group_name = azurerm_resource_group.fcg.name
  location            = azurerm_resource_group.fcg.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

resource "azurerm_kubernetes_cluster" "fcg" {
  name                = var.cluster_name
  location            = azurerm_resource_group.fcg.location
  resource_group_name = azurerm_resource_group.fcg.name
  dns_prefix          = "${local.prefix}-${random_string.suffix.result}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  role_based_access_control_enabled = true
  local_account_disabled            = false
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count            = var.node_count
    max_count            = max(var.node_count, 3)
    os_disk_size_gb      = 64

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
    service_cidr        = "10.43.0.0/16"
    dns_service_ip      = "10.43.0.10"
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.fcg.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.fcg.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-${local.prefix}-github"
  resource_group_name = azurerm_resource_group.fcg.name
  location            = azurerm_resource_group.fcg.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "github" {
  for_each = toset(var.github_repositories)

  name                = "github-${lower(replace(each.value, "_", "-"))}"
  resource_group_name = azurerm_resource_group.fcg.name
  parent_id           = azurerm_user_assigned_identity.github.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_owner}/${each.value}:environment:production"
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                            = azurerm_container_registry.fcg.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_user_assigned_identity.github.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "github_aks_user" {
  scope                            = azurerm_kubernetes_cluster.fcg.id
  role_definition_name             = "Azure Kubernetes Service Cluster User Role"
  principal_id                     = azurerm_user_assigned_identity.github.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "github_aks_writer" {
  scope                            = azurerm_kubernetes_cluster.fcg.id
  role_definition_name             = "Azure Kubernetes Service RBAC Writer"
  principal_id                     = azurerm_user_assigned_identity.github.principal_id
  skip_service_principal_aad_check = true
}

resource "random_password" "database" {
  length  = 32
  special = false
}

resource "azurerm_postgresql_flexible_server" "fcg" {
  name                   = "${local.prefix}-${random_string.suffix.result}-pg"
  resource_group_name    = azurerm_resource_group.fcg.name
  location               = azurerm_resource_group.fcg.location
  version                = "16"
  delegated_subnet_id    = azurerm_subnet.postgres.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = "fcgadmin"
  administrator_password = random_password.database.result
  sku_name               = var.postgres_sku_name
  storage_mb             = 32768
  backup_retention_days  = 7

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
  tags       = local.tags
}

resource "azurerm_postgresql_flexible_server_database" "fcg" {
  name      = "fcg"
  server_id = azurerm_postgresql_flexible_server.fcg.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

resource "azurerm_cosmosdb_account" "mongo" {
  name                                  = "${local.prefix}-${random_string.suffix.result}-mongo"
  location                              = azurerm_resource_group.fcg.location
  resource_group_name                   = azurerm_resource_group.fcg.name
  offer_type                            = "Standard"
  kind                                  = "MongoDB"
  mongo_server_version                  = "4.2"
  free_tier_enabled                     = var.cosmos_enable_free_tier
  public_network_access_enabled         = true
  network_acl_bypass_for_azure_services = true
  is_virtual_network_filter_enabled     = true

  capabilities { name = "EnableMongo" }
  capabilities { name = "EnableServerless" }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.fcg.location
    failover_priority = 0
  }

  virtual_network_rule {
    id                                   = azurerm_subnet.aks.id
    ignore_missing_vnet_service_endpoint = false
  }

  tags = local.tags
}

resource "azurerm_cosmosdb_mongo_database" "catalog" {
  name                = "fcg_catalog"
  resource_group_name = azurerm_resource_group.fcg.name
  account_name        = azurerm_cosmosdb_account.mongo.name
}

resource "azurerm_managed_redis" "fcg" {
  name                      = "${local.prefix}-${random_string.suffix.result}-redis"
  resource_group_name       = azurerm_resource_group.fcg.name
  location                  = azurerm_resource_group.fcg.location
  sku_name                  = var.redis_sku_name
  high_availability_enabled = var.redis_high_availability_enabled
  public_network_access     = "Enabled"

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
    clustering_policy                  = "NoCluster"
    eviction_policy                    = "AllKeysLRU"
  }

  tags = local.tags
}

data "ec_stack" "latest" {
  version_regex = "latest"
  region        = var.elastic_region
}

resource "ec_deployment" "search" {
  name                   = "${local.prefix}-search"
  region                 = var.elastic_region
  version                = data.ec_stack.latest.version
  deployment_template_id = var.elastic_deployment_template

  elasticsearch = {
    hot = {
      size        = "1g"
      zone_count  = 1
      autoscaling = {}
    }
  }
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "random_password" "administrator" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-=?_"
}

resource "random_password" "grafana" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-=?_"
}

resource "azurerm_key_vault" "fcg" {
  name                       = "${local.compact}kv"
  location                   = azurerm_resource_group.fcg.location
  resource_group_name        = azurerm_resource_group.fcg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Purge"
    ]
  }

  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = azurerm_kubernetes_cluster.fcg.key_vault_secrets_provider[0].secret_identity[0].object_id
    secret_permissions = ["Get", "List"]
  }

  tags = local.tags
}

locals {
  postgres_connection = "Host=${azurerm_postgresql_flexible_server.fcg.fqdn};Port=5432;Database=${azurerm_postgresql_flexible_server_database.fcg.name};Username=${azurerm_postgresql_flexible_server.fcg.administrator_login};Password=${random_password.database.result};SSL Mode=Require;Trust Server Certificate=true"
  redis_connection    = "${azurerm_managed_redis.fcg.hostname}:${azurerm_managed_redis.fcg.default_database[0].port},password=${azurerm_managed_redis.fcg.default_database[0].primary_access_key},ssl=true,abortConnect=false"
  runtime_secret_values = {
    "jwt-secret-key"         = random_password.jwt.result
    "rabbitmq-username"      = var.rabbitmq_username
    "rabbitmq-password"      = random_password.rabbitmq.result
    "admin-email"            = var.admin_email
    "admin-password"         = random_password.administrator.result
    "users-database"         = local.postgres_connection
    "catalog-database"       = local.postgres_connection
    "mongodb-connection"     = azurerm_cosmosdb_account.mongo.primary_mongodb_connection_string
    "redis-connection"       = local.redis_connection
    "elasticsearch-uri"      = ec_deployment.search.elasticsearch.https_endpoint
    "elasticsearch-username" = ec_deployment.search.elasticsearch_username
    "elasticsearch-password" = ec_deployment.search.elasticsearch_password
    "grafana-password"       = random_password.grafana.result
  }
}

resource "azurerm_key_vault_secret" "runtime" {
  for_each = toset([
    "jwt-secret-key",
    "rabbitmq-username",
    "rabbitmq-password",
    "admin-email",
    "admin-password",
    "users-database",
    "catalog-database",
    "mongodb-connection",
    "redis-connection",
    "elasticsearch-uri",
    "elasticsearch-username",
    "elasticsearch-password",
    "grafana-password"
  ])

  name         = each.value
  value        = local.runtime_secret_values[each.value]
  key_vault_id = azurerm_key_vault.fcg.id
  tags         = local.tags
}
