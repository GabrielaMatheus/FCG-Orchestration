# Evidencias locais - Fase 4

Data da ultima validacao: 17/11/2026.

## Resultados automatizados

| Evidencia | Resultado |
| --- | --- |
| UsersAPI | 4/4 testes aprovados em Release |
| CatalogAPI | 7/7 testes aprovados em Release |
| Imagens Docker | UsersAPI, CatalogAPI e PaymentsAPI construidas com sucesso |
| Autenticacao | Rota protegida recusou requisicao sem JWT com HTTP 401 |
| Cache Redis | Segunda consulta retornou `X-Cache: HIT` em 46 ms |
| Busca avancada | `Avetura` retornou `Aventura Espacial` com score 2,5221322 |
| MongoDB | Avaliacao criada e consultada pelo endpoint de reviews |
| OpenSearch | Container saudavel e cluster funcional |
| Prometheus | Servidor pronto |
| Grafana | Banco interno com status `ok` |

## Infraestrutura preparada

- Terraform valido para AKS, ACR, PostgreSQL Flexible Server, Cosmos DB MongoDB, Azure Managed Redis, Elastic Cloud e Key Vault.
- Overlay Kustomize Azure renderizado com 15 recursos.
- Workflows GitHub Actions com build, testes, Trivy, push no ACR e rolling update no AKS.
- OIDC e Managed Identity sem client secret persistente.
- Manifests com duas replicas, probes e `maxUnavailable: 0`.

## Limitacao da demonstracao

A ativacao da assinatura Azure foi bloqueada durante a verificacao da forma de pagamento. Por isso, nenhum recurso cloud foi criado e a demonstracao funcional foi realizada no Docker Desktop. O codigo de infraestrutura e os pipelines permanecem prontos para provisionamento quando houver uma assinatura ativa.
