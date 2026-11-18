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

- Ambiente executado: Docker Desktop com Docker Compose
- Gateway: Kong (`http://localhost:8000`)
- Containers: UsersAPI, CatalogAPI, PaymentsAPI, RabbitMQ, MongoDB, Redis, OpenSearch, Prometheus, Grafana e Azurite
- Infraestrutura cloud preparada: Terraform para Microsoft Azure, AKS, ACR, PostgreSQL, Cosmos DB, Redis, Elastic Cloud e Key Vault
- Data da demonstracao: 17/11/2026
- Limitacao: a assinatura Azure nao foi ativada devido a falha na verificacao da forma de pagamento; nenhum recurso cloud foi apresentado como executado

## Resumo

A FCG e o mesmo projeto iniciado como monolito na Fase 1, separado em microsservicos e mensageria na Fase 2 e ampliado com Kong, Azure Functions e observabilidade na Fase 3. Na Fase 4, a arquitetura foi preparada para Microsoft Azure com CI/CD, persistencia poliglota, cache distribuido e busca avancada. O Terraform define AKS, ACR, PostgreSQL Flexible Server, Cosmos DB MongoDB, Azure Managed Redis, Elastic Cloud e Key Vault. A ativacao da assinatura Azure foi bloqueada pela verificacao da forma de pagamento, portanto a demonstracao funcional foi executada localmente, sem alegar um deploy cloud inexistente. No Docker Desktop foram validados JWT, MongoDB, Redis com `X-Cache: HIT`, busca fuzzy por relevancia no OpenSearch, Prometheus e Grafana. As imagens Docker, manifests Kubernetes, scripts de provisionamento e pipelines GitHub Actions permanecem prontos para uma assinatura ativa.

## Evidencias tecnicas

- UsersAPI: 4/4 testes aprovados em Release.
- CatalogAPI: 7/7 testes aprovados em Release.
- Busca fuzzy: `Avetura` retornou `Aventura Espacial` por relevancia.
- Cache: segunda consulta retornou `X-Cache: HIT`.
- NoSQL: avaliacao criada e consultada no MongoDB.
- Validacao detalhada: https://github.com/GabrielaMatheus/FCG-Orchestration/blob/main/VALIDACAO-FASE4.md
