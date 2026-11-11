# Roteiro do Pitch Final - ate 25 minutos

## 0:00-2:00 - Contexto e arquitetura

- Apresentar o problema de escala, latencia e entrega manual.
- Mostrar o diagrama do README.
- Explicar PostgreSQL para dados transacionais, Cosmos DB MongoDB para avaliacoes, Redis para cache e Elastic Cloud para busca.

## 2:00-6:00 - Infraestrutura Azure

- Mostrar o Resource Group `rg-fcg-prod` no Portal do Azure.
- Abrir AKS e exibir o node pool gerenciado.
- Mostrar o Azure Container Registry e os repositorios privados.
- Mostrar PostgreSQL, Cosmos DB, Managed Redis e Key Vault sem revelar valores.
- Abrir o painel Elastic Cloud e mostrar que o deployment usa Microsoft Azure.
- Executar `kubectl -n fcg get pods,svc` e destacar o IP do Load Balancer.

## 6:00-10:00 - NoSQL e cache

- Criar uma avaliacao com metadata flexivel.
- Mostrar o documento no Cosmos DB usando a API para MongoDB.
- Chamar `GET /api/games` duas vezes.
- Mostrar `X-Cache: MISS`/`HIT`, os tempos do script e explicar a chave no Redis.
- Explicar expiracao e invalidacao.

## 10:00-14:00 - Busca avancada

- Criar ou editar um jogo.
- Mostrar o documento no indice `fcg-games`.
- Buscar por um termo correto.
- Buscar por `Avetura` e demonstrar tolerancia ao erro.
- Mostrar o campo `score` e a ordem por relevancia.

## 14:00-20:00 - Live deploy

- Fazer uma alteracao pequena e visivel no CatalogAPI ou UsersAPI.
- Commit e push em `main`.
- Mostrar build, testes, Trivy, tag SHA e push no ACR.
- Acompanhar `kubectl get pods -w` e destacar o rolling update.
- Fazer requisicoes durante o rollout para demonstrar ausencia de downtime.
- Confirmar a nova versao em producao.

## 20:00-23:00 - Seguranca e resiliencia

- Mostrar que YAMLs referenciam `fcg-runtime`, sem valores.
- Mostrar Key Vault e o Secrets Store CSI Driver sem abrir os segredos.
- Explicar OIDC do GitHub e a Managed Identity.
- Mostrar duas replicas, probes, autoscaling e `maxUnavailable: 0`.
- Mostrar subnet privada do PostgreSQL e conexoes TLS.

## 23:00-25:00 - Fechamento

- Recapitular os cinco requisitos obrigatorios.
- Mostrar o checklist concluido.
- Exibir os links dos repositorios, README e video.

## Evidencias obrigatorias na gravacao

- Portal Azure e pods do AKS.
- ACR e pipeline completa com live deploy.
- Cosmos DB MongoDB com avaliacao flexivel.
- `X-Cache: HIT` e comparacao de tempo.
- `/search` com erro de digitacao e scores.
- Key Vault e Secrets referenciados sem revelar valores.
