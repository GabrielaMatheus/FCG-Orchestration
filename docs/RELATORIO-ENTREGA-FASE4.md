# Relatorio de Entrega - FIAP Cloud Games - Fase 4

## Grupo

| Nome completo | Username no Discord |
| --- | --- |
| PREENCHER | PREENCHER |
| PREENCHER | PREENCHER |

## Documentacao

- README principal: https://github.com/GabrielaMatheus/FCG-Orchestration

## Repositorios

- UsersAPI: https://github.com/GabrielaMatheus/FCG-UsersAPI
- CatalogAPI: https://github.com/GabrielaMatheus/FCG-CatalogAPI
- PaymentsAPI: https://github.com/GabrielaMatheus/FCG-PaymentsAPI
- NotificationsFunction: https://github.com/GabrielaMatheus/FCG-NotificationsFunction
- Orchestration: https://github.com/GabrielaMatheus/FCG-Orchestration

## Video

- YouTube ou Google Drive: PREENCHER

## Ambiente demonstrado

- Provedor: Microsoft Azure
- Kubernetes: Azure Kubernetes Service (AKS)
- Registry: Azure Container Registry (ACR)
- Busca gerenciada: Elastic Cloud hospedado no Azure
- URL do Azure Load Balancer: PREENCHER
- Data da demonstracao: PREENCHER

## Resumo

A FCG foi evoluida para uma arquitetura cloud-native no Microsoft Azure com CI/CD, persistencia poliglota, cache distribuido e busca avancada. UsersAPI e CatalogAPI rodam no AKS, usam imagens privadas do ACR e recebem segredos do Azure Key Vault em runtime. Dados transacionais ficam no PostgreSQL Flexible Server, avaliacoes flexiveis usam Cosmos DB for MongoDB, consultas do catalogo usam Azure Managed Redis e a busca fuzzy e atendida pelo Elastic Cloud hospedado no Azure.
