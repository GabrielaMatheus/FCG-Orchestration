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

A FCG e o mesmo projeto iniciado como monolito na Fase 1, separado em microsservicos e mensageria na Fase 2 e ampliado com Kong, Azure Functions e observabilidade na Fase 3. Na Fase 4, essa arquitetura foi evoluida para uma plataforma cloud-native no Microsoft Azure com CI/CD, persistencia poliglota, cache distribuido e busca avancada. UsersAPI e CatalogAPI rodam no AKS, usam imagens privadas do ACR e recebem segredos do Azure Key Vault em runtime. PaymentsAPI, RabbitMQ, Kong e NotificationsFunction continuam compondo o fluxo existente. Dados transacionais ficam no PostgreSQL Flexible Server, avaliacoes flexiveis usam Cosmos DB for MongoDB, consultas do catalogo usam Azure Managed Redis e a busca fuzzy e atendida pelo Elastic Cloud hospedado no Azure.
