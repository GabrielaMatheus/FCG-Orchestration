# FIAP Cloud Games - Orquestracao

Repositório responsável pela execução integrada dos microsserviços da Fase 2 do FIAP Cloud Games.

Cada microsserviço possui seu próprio repositório Git, Dockerfile, README e manifestos Kubernetes. Este repositório concentra apenas os arquivos necessários para subir a aplicação completa em ambiente local e documentar os contratos de integração.

## Repositórios dos microsserviços

| Microsserviço | Responsabilidade | Repositório |
| --- | --- | --- |
| UsersAPI | Cadastro, autenticação JWT e autorização de usuários | `FCG-UsersAPI` |
| CatalogAPI | CRUD de jogos, início da compra e atualização da biblioteca | `FCG-CatalogAPI` |
| PaymentsAPI | Simulação de pagamento e publicação do resultado | `FCG-PaymentsAPI` |
| NotificationsAPI | Simulação de e-mails de boas-vindas e confirmação de compra | `FCG-NotificationsAPI` |

## Estrutura esperada no ambiente local

O `docker-compose.yml` espera que os cinco repositórios fiquem lado a lado dentro da mesma pasta:

```text
FCG-Microservices/
├── FCG-UsersAPI/
├── FCG-CatalogAPI/
├── FCG-PaymentsAPI/
├── FCG-NotificationsAPI/
└── FCG-Orchestration/
```

## Execução com Docker Compose

Na raiz deste repositório, o comando abaixo sobe RabbitMQ e os quatro microsserviços:

```powershell
docker compose up --build
```

Serviços expostos localmente:

| Serviço | URL |
| --- | --- |
| UsersAPI | `http://localhost:5101` |
| CatalogAPI | `http://localhost:5102` |
| PaymentsAPI | `http://localhost:5103` |
| NotificationsAPI | `http://localhost:5104` |
| RabbitMQ Management | `http://localhost:15672` |

Credenciais padrão do RabbitMQ em desenvolvimento:

```text
usuario: guest
senha: guest
```

## Variáveis de ambiente

O arquivo `.env.example` lista as variáveis usadas pelo `docker-compose.yml`.

| Variável | Finalidade |
| --- | --- |
| `RABBITMQ_USER` | Usuário do RabbitMQ |
| `RABBITMQ_PASSWORD` | Senha do RabbitMQ |
| `JWT_SECRET` | Chave de assinatura do JWT da UsersAPI |
| `ADMIN_EMAIL` | E-mail do administrador inicial da UsersAPI |
| `ADMIN_PASSWORD` | Senha do administrador inicial da UsersAPI |
| `CATALOG_DATABASE` | Connection string local da CatalogAPI |
| `PAYMENTS_DATABASE` | Connection string local da PaymentsAPI |

## Fluxo de mensageria

A comunicação assíncrona entre os microsserviços usa RabbitMQ com MassTransit.

```text
UsersAPI
  publica UserCreatedEvent
        ↓
NotificationsAPI
  consome UserCreatedEvent e simula e-mail de boas-vindas

CatalogAPI
  publica OrderPlacedEvent
        ↓
PaymentsAPI
  consome OrderPlacedEvent e publica PaymentProcessedEvent
        ↓
CatalogAPI
  consome PaymentProcessedEvent e atualiza biblioteca se aprovado
        ↓
NotificationsAPI
  consome PaymentProcessedEvent e simula e-mail de confirmação se aprovado
```

## Contratos de integração

Os contratos compartilhados estão documentados em `contracts/Events.cs`.

Para manter a compatibilidade no MassTransit, os microsserviços devem usar o mesmo namespace dos eventos:

```csharp
namespace FiapCloudGames.Contracts;
```

## Kubernetes

Cada repositório de microsserviço contém seus próprios manifests Kubernetes com `Deployment`, `Service`, `ConfigMap` e `Secret`.

Este repositório inclui apenas o manifesto de apoio do RabbitMQ em:

```text
k8s/rabbitmq.yaml
```

Aplicação do RabbitMQ no cluster:

```powershell
kubectl apply -f k8s/rabbitmq.yaml
```

Depois disso, os manifests de cada microsserviço podem ser aplicados a partir dos respectivos repositórios.
