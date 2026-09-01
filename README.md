# FIAP Cloud Games - Orquestração

Repositório responsável pela execução integrada da Fase 3 do FIAP Cloud Games.

Nesta fase, a arquitetura de microsserviços foi profissionalizada com API Gateway, serverless, observabilidade, persistência poliglota com MongoDB e cache distribuído com Redis.

## Stack escolhida

| Requisito | Implementação |
| --- | --- |
| API Gateway | Kong Gateway em modo DB-less |
| Serverless | Azure Functions .NET 8 isolated worker com RabbitMQ Trigger |
| Observabilidade | Prometheus + Grafana |
| NoSQL | MongoDB na CatalogAPI para avaliações flexíveis de jogos |
| Cache distribuído | Redis na CatalogAPI para consultas do catálogo |
| Mensageria | RabbitMQ + MassTransit |

## Repositórios

| Repositório | Responsabilidade |
| --- | --- |
| `FCG-UsersAPI` | Cadastro, login, JWT, autorização e publicação de `UserCreatedEvent` |
| `FCG-CatalogAPI` | Catálogo, biblioteca, compra, MongoDB para reviews e Redis para cache |
| `FCG-PaymentsAPI` | Simulação de pagamento e publicação de `PaymentProcessedEvent` |
| `FCG-NotificationsFunction` | Função serverless acionada por filas RabbitMQ |
| `FCG-Orchestration` | Docker Compose, Kong, RabbitMQ, Prometheus, Grafana, MongoDB, Redis e manifests Kubernetes |

## Estrutura local esperada

O `docker-compose.yml` espera que os repositórios fiquem lado a lado:

```text
FCG-Microservices/
├── FCG-UsersAPI/
├── FCG-CatalogAPI/
├── FCG-PaymentsAPI/
├── FCG-NotificationsFunction/
└── FCG-Orchestration/
```

## Execução local da infraestrutura e microsserviços

Na raiz deste repositório:

```powershell
docker compose up --build
```

Esse comando sobe RabbitMQ, Kong, UsersAPI, CatalogAPI, PaymentsAPI, MongoDB, Redis, Prometheus e Grafana.

A função serverless não fica no compose principal porque substitui o container contínuo de notificações. Ela roda separadamente com Azure Functions Core Tools.

## Execução local da NotificationsFunction

Em outro terminal:

```powershell
cd "C:\Users\gabri\OneDrive\Documentos\FCG-Microservices\FCG-NotificationsFunction"
Copy-Item .\src\FiapCloudGames.NotificationsFunction\local.settings.example.json .\src\FiapCloudGames.NotificationsFunction\local.settings.json
func start --script-root .\src\FiapCloudGames.NotificationsFunction
```

## URLs locais

| Componente | URL |
| --- | --- |
| API Gateway Kong | `http://localhost:8000` |
| Kong Admin API local | `http://localhost:8001` |
| UsersAPI direta | `http://localhost:5101` |
| CatalogAPI direta | `http://localhost:5102` |
| PaymentsAPI direta | `http://localhost:5103` |
| RabbitMQ Management | `http://localhost:15672` |
| Prometheus | `http://localhost:9090` |
| Grafana | `http://localhost:3000` |

Credenciais locais:

```text
RabbitMQ: guest / guest
Grafana: admin / admin
```

## Gateway

O Kong é a porta de entrada única para chamadas externas:

```text
http://localhost:8000/api/users
http://localhost:8000/api/games
http://localhost:8000/api/users/{userId}/games/{gameId}/purchase
```

As rotas de `CatalogAPI` usam o plugin JWT do Kong. O token é emitido pela `UsersAPI` e enviado no header:

```text
Authorization: Bearer <token>
```

## Fluxo de mensageria

```text
UsersAPI
  publica UserCreatedEvent
        ↓
NotificationsFunction
  consome a fila notifications-user-created e registra EMAIL_SENT Type=Welcome

CatalogAPI
  publica OrderPlacedEvent
        ↓
PaymentsAPI
  consome OrderPlacedEvent e publica PaymentProcessedEvent
        ↓
CatalogAPI
  consome PaymentProcessedEvent e atualiza biblioteca se aprovado
        ↓
NotificationsFunction
  consome a fila notifications-payment-processed e registra EMAIL_SENT Type=PurchaseConfirmation
```

## Observabilidade

A opção escolhida foi a stack open-source Prometheus + Grafana.

UsersAPI e CatalogAPI expõem métricas no endpoint:

```text
/metrics
```

O Prometheus coleta essas métricas e o Grafana possui dashboard provisionado automaticamente para visualizar contagem de requisições, latência HTTP, taxa de erros e chamadas roteadas pelo Kong.

## NoSQL e cache

Na `CatalogAPI`, o MongoDB foi usado para armazenar avaliações de jogos:

```text
GET /api/games/{id}/reviews
POST /api/games/{id}/reviews
```

Esse dado foi escolhido para NoSQL porque avaliações podem crescer bastante e aceitar campos flexíveis em `metadata`.

O Redis foi usado como cache distribuído das consultas do catálogo, reduzindo leituras repetidas no SQLite.

## Kubernetes

Este repositório versiona manifests Kubernetes para RabbitMQ, Kong Gateway, Prometheus/Grafana e MongoDB/Redis.

Os microsserviços continuam com seus próprios manifests nos respectivos repositórios.

Aplicação da infraestrutura:

```powershell
kubectl apply -f k8s/rabbitmq.yaml
kubectl apply -f k8s/mongodb-redis.yaml
kubectl apply -f k8s/kong-gateway.yaml
kubectl apply -f k8s/observability.yaml
```

Antes de usar em ambiente real, substituir valores `CHANGE-ME` em Secrets.

## Contratos de integração

Os contratos compartilhados estão documentados em:

```text
contracts/Events.cs
```

Todos os microsserviços usam o namespace:

```csharp
namespace FiapCloudGames.Contracts;
```
