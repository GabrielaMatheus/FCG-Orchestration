# Historico evolutivo do FIAP Cloud Games

O FIAP Cloud Games nao foi recriado na Fase 4. Ele e o mesmo projeto academico iniciado na Fase 1 e aprimorado a cada etapa da pos-graduacao. Este arquivo registra a continuidade das decisoes e evita tratar uma nova fase como um sistema separado.

## Fase 1 - API monolitica

O projeto nasceu no repositorio `FCG-TC-PosTech` como uma API .NET 8 unica.

Foram implementados:

- Minimal API para usuarios e jogos;
- Entity Framework Core com SQLite e migrations;
- cadastro, login e perfis Usuario/Administrador;
- autenticacao e autorizacao JWT;
- Swagger;
- middleware de erros e logs estruturados;
- testes xUnit;
- documentacao DDD e Event Storming para usuarios e jogos.

Essa fase definiu o dominio e as regras que continuam validas nas fases seguintes.

## Fase 2 - microsservicos e mensageria

O monolito foi dividido em servicos autonomos:

- `FCG-UsersAPI`;
- `FCG-CatalogAPI`;
- `FCG-PaymentsAPI`;
- `FCG-NotificationsAPI`, posteriormente substituida pela Function;
- `FCG-Orchestration`, responsavel por conectar o ambiente.

Foram acrescentados RabbitMQ com MassTransit, eventos assincronos, Dockerfiles multi-stage, Docker Compose, Kubernetes, ConfigMaps, Secrets e repositorios separados.

O fluxo principal passou a ser:

```text
UsersAPI -> UserCreatedEvent -> notificacao
CatalogAPI -> OrderPlacedEvent -> PaymentsAPI
PaymentsAPI -> PaymentProcessedEvent -> CatalogAPI + notificacao
```

## Fase 3 - gateway, serverless, dados e observabilidade

A arquitetura da Fase 2 foi mantida e recebeu:

- Kong como ponto de entrada unico;
- `FCG-NotificationsFunction` em Azure Functions .NET 8, substituindo a NotificationsAPI em container;
- MongoDB para avaliacoes;
- Redis para cache do catalogo;
- Prometheus e Grafana para metricas;
- Loki para logs centralizados da Function;
- manifests Kubernetes e validacao integrada do fluxo de compra.

A Azure Function ja era Azure desde esta fase. Ela possui repositorio proprio e Bicep em `FCG-NotificationsFunction/infra/main.bicep`. Na entrega da Fase 3, a Function foi executada localmente com Azure Functions Core Tools; o Bicep foi validado, mas a infraestrutura nao foi publicada em uma assinatura Azure.

## Fase 4 - nuvem gerenciada, busca e entrega continua

A Fase 4 continua usando os cinco repositorios da Fase 3. Nao substitui o dominio, o Gateway, o fluxo de pagamento, o RabbitMQ nem a Azure Function.

As melhorias desta fase sao:

- AKS como Kubernetes gerenciado;
- Azure Container Registry privado;
- PostgreSQL Flexible Server para os dados transacionais compartilhados;
- Cosmos DB for MongoDB para as avaliacoes;
- Azure Managed Redis para cache;
- Elastic Cloud hospedado no Azure para busca fuzzy e relevancia;
- Azure Key Vault e Secrets Store CSI Driver;
- CI/CD das UsersAPI e CatalogAPI com GitHub Actions, Trivy, ACR e rolling update;
- Terraform para a infraestrutura Azure;
- Kong exposto por Azure Load Balancer.

## O que permanece de cada fase

| Componente | Origem | Situacao na Fase 4 |
| --- | --- | --- |
| Dominio de usuarios e jogos | Fase 1 | Preservado e distribuido entre as APIs |
| JWT e perfis | Fase 1 | Preservados; Kong protege as rotas externas |
| UsersAPI | Fase 2 | Evoluida para PostgreSQL, ACR, AKS e CI/CD |
| CatalogAPI | Fase 2 | Evoluida com Cosmos DB, Redis e Elasticsearch |
| PaymentsAPI | Fase 2 | Preservada no fluxo assincrono e implantada no AKS |
| RabbitMQ/MassTransit | Fase 2 | Preservados no AKS |
| Kong | Fase 3 | Preservado e exposto pelo Load Balancer Azure |
| NotificationsFunction | Fase 3 | Preservada como Azure Function e repositorio proprio |
| Prometheus/Grafana/Loki | Fase 3 | Mantidos para a demonstracao local; a Fase 4 nao os substitui |
| MongoDB/Redis | Fase 3 | Evoluidos para servicos gerenciados no Azure |
| Busca fuzzy e CI/CD | Fase 4 | Novos recursos desta fase |

## Repositorios oficiais da solucao atual

- <https://github.com/GabrielaMatheus/FCG-UsersAPI>
- <https://github.com/GabrielaMatheus/FCG-CatalogAPI>
- <https://github.com/GabrielaMatheus/FCG-PaymentsAPI>
- <https://github.com/GabrielaMatheus/FCG-NotificationsFunction>
- <https://github.com/GabrielaMatheus/FCG-Orchestration>

O repositorio `FCG-TC-PosTech` registra a origem monolitica e o trabalho da Fase 1. Os cinco repositorios acima representam a arquitetura evoluida a partir da Fase 2.
