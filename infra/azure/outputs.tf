output "resource_group_name" {
  value = azurerm_resource_group.fcg.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.fcg.name
}

output "azure_subscription_id" {
  value = var.azure_subscription_id
}

output "azure_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "github_actions_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

output "acr_name" {
  value = azurerm_container_registry.fcg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.fcg.login_server
}

output "key_vault_name" {
  value = azurerm_key_vault.fcg.name
}

output "key_vault_csi_client_id" {
  value = azurerm_kubernetes_cluster.fcg.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "elastic_deployment_id" {
  value = ec_deployment.search.id
}

output "elastic_endpoint" {
  value = ec_deployment.search.elasticsearch.https_endpoint
}

output "github_repository_variables" {
  description = "Create these variables in both API repositories. ACR_REPOSITORY differs per repository."
  value = {
    AZURE_CLIENT_ID       = azurerm_user_assigned_identity.github.client_id
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = var.azure_subscription_id
    AZURE_RESOURCE_GROUP  = azurerm_resource_group.fcg.name
    AKS_CLUSTER_NAME      = azurerm_kubernetes_cluster.fcg.name
    ACR_NAME              = azurerm_container_registry.fcg.name
    ACR_LOGIN_SERVER      = azurerm_container_registry.fcg.login_server
  }
}

output "kong_load_balancer_command" {
  value = "kubectl -n fcg get service kong"
}
