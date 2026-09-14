# Validação da versão de entrega — Fase 3

Data: 14/09/2026.

## Ambiente

Windows, Docker Desktop com containers Linux, cluster kind `fcg-fase3`, namespace Kubernetes `fcg`. A NotificationsFunction executa em Azure Functions Core Tools com .NET 8 e utiliza Azurite para o armazenamento local do host.

Os dez Deployments ficaram disponíveis: UsersAPI, CatalogAPI, PaymentsAPI, RabbitMQ, MongoDB, Redis, Kong, Prometheus, Grafana e Loki. A Function permanece fora do container contínuo da antiga NotificationsAPI.

## Verificações realizadas

| Verificação | Resultado |
| --- | --- |
| Build Docker dos três microsserviços | Aprovado |
| Build da NotificationsFunction | Aprovado, sem avisos ou erros |
| Testes UsersAPI | 4 aprovados |
| Testes CatalogAPI | 4 aprovados |
| Testes PaymentsAPI | 3 aprovados |
| Compilação do Bicep | Aprovada; sem publicação na Azure |
| Cadastro e login pelo Gateway | Aprovados |
| Rotas protegidas sem JWT / JWT inválido | HTTP 401 |
| Tentativa de acessar APIs por prefixos do Swagger | HTTP 404 |
| Documentação Swagger de Users e Catalog pelo Gateway | HTTP 200 |
| Avaliação gravada e consultada no MongoDB | Aprovada |
| Resultado de consulta armazenado no Redis | Confirmado diretamente no Redis |
| Compra, processamento do pagamento e atualização da biblioteca | Aprovados |
| Notificações de boas-vindas e compra no Loki | Confirmadas para a mesma conta de teste |
| Coleta Prometheus de UsersAPI, CatalogAPI e Kong | UP |
| Provisionamento dos sete painéis do Grafana | Confirmado |
| Consultas PromQL dos seis painéis de métricas | Executadas com sucesso |

O fluxo integrado foi exercitado no Compose e no Kubernetes. A conferência final foi executada no Kubernetes com o script `scripts/Test-Fase3.ps1`, após a atualização do Gateway. Cada execução cria uma conta fictícia única e preserva seus dados de demonstração.

## Decisões de execução

- O Kong é o ponto de entrada de negócio; as APIs não publicam portas diretas no Compose e usam Services internos no Kubernetes.
- O segredo JWT é injetado no template do Kong e compartilhado com as APIs por configuração; no cluster usa Kubernetes Secret.
- O RabbitMQ cria usuário, permissões e filas também em uma instalação nova. O hash da senha é gerado na inicialização.
- A observabilidade da apresentação usa Deployments Kubernetes com fontes de dados e dashboard provisionados por ConfigMaps.
- A Function simula e-mails e envia os registros ao Loki, consultado pelo Grafana. Não há envio de e-mail real.
- O ambiente de nuvem não foi implantado. O Bicep foi compilado localmente; sua publicação depende de assinatura Azure e conectividade com o broker e o Loki.

## Materiais acadêmicos

O código e a validação técnica não substituem o vídeo de até 20 minutos nem o relatório de entrega com identificação, usernames do Discord e links. Esses materiais devem ser publicados e enviados conforme o enunciado. O README é o guia central de execução e demonstração.
