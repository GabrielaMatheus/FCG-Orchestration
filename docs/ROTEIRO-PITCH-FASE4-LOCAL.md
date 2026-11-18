# Roteiro de entrega local - Fase 4 (15 a 20 minutos)

Este roteiro e a alternativa de contingencia quando a ativacao da assinatura Azure nao e concluida. A apresentacao deve ser transparente: a infraestrutura Azure foi implementada como codigo, mas a execucao demonstrada e local.

## 0:00-2:00 - Contexto e evolucao

- Apresentar o FIAP Cloud Games e a continuidade das Fases 1 a 4.
- Mostrar o diagrama do `README.md`.
- Explicar PostgreSQL, MongoDB, Redis e Elasticsearch/OpenSearch.

## 2:00-5:00 - Arquitetura e infraestrutura como codigo

- Mostrar `infra/azure/main.tf`, destacando AKS, ACR, PostgreSQL, Cosmos DB, Redis, Elastic Cloud e Key Vault.
- Mostrar `k8s/overlays/azure` e as duas replicas com rolling update.
- Informar que a assinatura Azure nao foi ativada por falha de verificacao do pagamento; nenhum recurso cloud deve ser apresentado como executado.

## 5:00-8:00 - Solucao local em containers

- Abrir o Docker Desktop e mostrar os containers.
- No terminal, executar `docker ps --filter "name=fcg-orchestration"`.
- Mostrar Kong, UsersAPI, CatalogAPI, PaymentsAPI, RabbitMQ, MongoDB, Redis, OpenSearch, Prometheus e Grafana.

## 8:00-12:00 - Cache, busca e NoSQL

- Executar `scripts/Test-Fase4.ps1`.
- Destacar a segunda requisicao com `X-Cache: HIT`.
- Destacar a busca `Avetura` retornando `Aventura Espacial` por relevancia.
- Mostrar uma avaliacao criada e consultada pelo endpoint de reviews, persistida no MongoDB.

## 12:00-15:00 - CI/CD e seguranca

- Mostrar `.github/workflows` em UsersAPI e CatalogAPI.
- Explicar build, testes, imagem por SHA, Trivy, ACR e rolling update no AKS.
- Mostrar que os manifests referenciam `fcg-runtime` e nao possuem senhas reais.
- Mostrar OIDC, Key Vault, probes e `maxUnavailable: 0` no codigo.

## 15:00-18:00 - Evidencias e fechamento

- Mostrar `VALIDACAO-FASE4.md` e `docs/CHECKLIST-FASE4.md`.
- Exibir os testes: UsersAPI 4/4 e CatalogAPI 7/7.
- Mostrar os cinco repositorios no GitHub.
- Encerrar dizendo claramente que o deploy Azure esta pronto como IaC, mas nao foi executado por bloqueio externo de faturamento.

## Nao esquecer

- Grave a tela e o microfone.
- Nao mostre senhas, cartao, tokens ou chaves.
- Nao afirme que o AKS ou os servicos Azure foram executados.
- Publique no YouTube como nao listado ou no Google Drive com acesso por link.
