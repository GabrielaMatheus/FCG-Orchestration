# FIAP Cloud Games — Fase 3

Aplicação de venda de jogos com microsserviços .NET 8, API Gateway, processamento assíncrono, função serverless, observabilidade, MongoDB e Redis.

## Arquitetura

O Kong recebe as chamadas externas. Cadastro e login são públicos; as demais rotas de negócio exigem JWT. A UsersAPI emite o token, e Kong e APIs validam a autenticação. As APIs aplicam as regras de autorização por usuário e perfil.

A CatalogAPI publica OrderPlacedEvent no RabbitMQ. A PaymentsAPI simula o pagamento e publica PaymentProcessedEvent. CatalogAPI e NotificationsFunction consomem esse evento independentemente: uma atualiza a biblioteca; a outra simula a confirmação por e-mail. O cadastro publica UserCreatedEvent e aciona a mensagem de boas-vindas.

Os e-mails são simulados, sem envio real. A NotificationsFunction registra EMAIL_SENT no console e no Loki; o Grafana permite consultar os logs centralizados. A Function usa Azure Functions Core Tools no ambiente local, fora do container contínuo da antiga NotificationsAPI.

| Requisito | Implementação |
| --- | --- |
| Gateway | Kong DB-less com JWT e rotas versionadas |
| Serverless | Azure Functions .NET 8 isolated, RabbitMQ Trigger |
| Observabilidade — Opção A | Prometheus + Grafana implantáveis por manifestos Kubernetes |
| Logs centralizados | Loki + painel de logs no Grafana |
| NoSQL | MongoDB.Driver; avaliações com metadata flexível |
| Cache distribuído | Redis com IDistributedCache; catálogo e consultas por ID |
| Mensageria | RabbitMQ + MassTransit |
| Persistência relacional | SQLite separado por serviço |

## Repositórios

- [UsersAPI](https://github.com/GabrielaMatheus/FCG-UsersAPI)
- [CatalogAPI](https://github.com/GabrielaMatheus/FCG-CatalogAPI)
- [PaymentsAPI](https://github.com/GabrielaMatheus/FCG-PaymentsAPI)
- [NotificationsFunction](https://github.com/GabrielaMatheus/FCG-NotificationsFunction)
- [Orchestration](https://github.com/GabrielaMatheus/FCG-Orchestration)

A NotificationsAPI pertence à Fase 2 e não participa da execução da Fase 3. Os contratos de eventos estão em contracts/Events.cs e usam o namespace FiapCloudGames.Contracts.

## Pré-requisitos e pastas

Docker Desktop iniciado com containers Linux, .NET 8 SDK, Azure Functions Core Tools v4 e PowerShell. O Node.js é necessário se Core Tools for instalado via npm. Para Kubernetes local: kubectl e kind.

Os cinco repositórios devem ficar lado a lado dentro de FCG-Microservices. Os comandos abaixo partem de FCG-Orchestration, exceto quando indicado.

## Execução rápida com Docker Compose

    docker compose up -d --build

Em outro terminal, na pasta FCG-NotificationsFunction:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\start-local.ps1

O script preserva local.settings.json existente e configura o Loki local. O Bypass vale somente para esse processo, sem alterar a política permanente do PowerShell. O terminal da Function deve permanecer aberto.

| Componente | Endereço local |
| --- | --- |
| Gateway | http://localhost:8000 |
| Swagger Users | http://localhost:8000/users-swagger/swagger/index.html |
| Swagger Catalog | http://localhost:8000/catalog-swagger/swagger/index.html |
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| RabbitMQ | http://localhost:15672 |
| Loki | http://localhost:3100 |

Grafana: admin / admin. RabbitMQ: guest / guest. Credenciais exclusivamente locais.
Administrador da aplicação: admin@fiap.com.br / Admin@123!, salvo alteração anterior.

UsersAPI, CatalogAPI e PaymentsAPI não publicam portas diretas no host. As interfaces de administração e observabilidade são ferramentas de desenvolvimento, não rotas públicas de negócio.

## Variáveis de ambiente

O arquivo .env é opcional e não deve ser versionado. Os padrões do Compose permitem a demonstração local.

| Variável | Uso |
| --- | --- |
| JWT_SECRET | Segredo compartilhado por UsersAPI, CatalogAPI e Kong; pelo menos 32 caracteres entre letras, números, _ e - |
| RABBITMQ_USER / RABBITMQ_PASSWORD | Credenciais do broker; o script gera o hash e importa usuário, permissões e filas |
| ADMIN_EMAIL / ADMIN_PASSWORD | Administrador inicial; mudar a variável não redefine uma conta já persistida |
| CATALOG_DATABASE | Connection string SQLite do catálogo |
| MONGODB_CONNECTION / MONGODB_DATABASE | Conexão e banco de avaliações |
| REDIS_CONNECTION | Endereço do Redis |

O Kong renderiza sua configuração a partir de um template sem segredo. No Kubernetes, recebe JWT_SECRET do Secret fcg-runtime. A mesma chave é usada nas APIs. Os padrões locais não representam uma configuração de produção.

## Execução da entrega com Kubernetes

A implantação usa um cluster kind chamado fcg-fase3 e namespace fcg. O contexto é informado explicitamente nos scripts. Todos os componentes do cluster são gerenciados por Deployments; os bancos possuem volumes persistentes. APIs e administração do Kong usam Services internos.

Instalação inicial do kind, caso necessário:

    winget install --id Kubernetes.kind --exact --source winget

Depois de instalar, abrir um novo PowerShell para atualizar o PATH. Criar o cluster apenas uma vez:

    kind create cluster --name fcg-fase3 --wait 120s

Na pasta FCG-Orchestration:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Deploy-Kubernetes.ps1

Esse script compila e carrega as imagens no kind, cria o Secret local, aplica a configuração com Kustomize e aguarda os Deployments. O arquivo kustomization.yaml é a entrada da implantação completa; os arquivos individuais em k8s dependem das configurações e Secrets criados por esse fluxo.

Para acessar o ambiente, em outro terminal:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Open-Kubernetes.ps1

| Componente Kubernetes | Endereço |
| --- | --- |
| Gateway | http://localhost:18000 |
| Grafana | http://localhost:13000 |
| Prometheus | http://localhost:19090 |
| Loki | http://localhost:13100 |
| RabbitMQ AMQP | localhost:5673 |

Os encaminhamentos ficam ativos enquanto o script estiver rodando. Ctrl+C os encerra sem apagar o cluster ou os dados.

A Function roda localmente conectada ao broker do Kubernetes. Encerrar a execução anterior da Function com Ctrl+C antes de iniciar este modo. Manter o Azurite disponível:

    docker compose up -d azurite

Na pasta FCG-NotificationsFunction:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\start-local.ps1 -RabbitMQConnection amqp://guest:guest@localhost:5673/ -LokiUrl http://localhost:13100

Docker Compose e Kubernetes possuem bancos e filas independentes. Uma conta ou compra criada em um ambiente não aparece automaticamente no outro.

## Teste integrado

Com a Function em execução, na pasta FCG-Orchestration:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Fase3.ps1

Para testar o Kubernetes:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Fase3.ps1 -BaseUrl http://localhost:18000 -GrafanaUrl http://localhost:13000 -PrometheusUrl http://localhost:19090 -LokiUrl http://localhost:13100 -CacheMode Kubernetes

O teste cria uma conta fictícia única, faz login, consulta jogos, grava e consulta uma avaliação no MongoDB, inicia uma compra, aguarda a biblioteca e verifica os dois tipos de notificação no Loki. Também verifica bloqueio sem JWT, saúde das coletas do Prometheus e disponibilidade do Grafana. Os dados de demonstração ficam persistidos; o teste não limpa os bancos.

Para conferir o Redis no Compose:

    docker compose exec -T redis redis-cli --scan --pattern "fcg-catalog:*"
    docker compose exec -T redis redis-cli TTL fcg-catalog:games:list

No Kubernetes:

    kubectl --context kind-fcg-fase3 -n fcg exec deployment/redis -- redis-cli --scan --pattern "fcg-catalog:*"

O cache expira após cinco minutos. Criação, edição e exclusão invalidam as entradas relacionadas; requisições repetidas consultam o Redis enquanto a entrada é válida.

## Observabilidade e demonstração

No Grafana, abrir o dashboard FIAP Cloud Games - Observabilidade, na pasta FIAP Cloud Games. Selecionar os últimos 15 minutos e gerar requisições pelo Gateway. Os painéis mostram total de requisições, contagem por código HTTP, requisições por segundo, latência p95, erros 5xx por segundo, chamadas do Kong e logs da Function. Sem tráfego suficiente, painéis baseados em rate podem levar alguns segundos para mostrar valores.

Em Explore, selecionar Loki e consultar:

    {service="notifications-function"}

O registro contém tipo, destinatário, assunto e corpo da notificação simulada. As duas notificações são produzidas por triggers de fila; a API não chama a Function diretamente.

No Prometheus, a página Targets deve mostrar users-api, catalog-api e kong como UP. Na implantação Kubernetes, o Grafana recebe automaticamente a fonte de dados e o dashboard por ConfigMaps.

## Escopo de implantação

O ambiente de demonstração é local: microsserviços e observabilidade no Kubernetes, Function no Azure Functions Core Tools e Storage emulado pelo Azurite. Não há publicação automática na Azure. O repositório da Function contém Bicep para o ambiente de nuvem, cuja implantação exige assinatura, conectividade com RabbitMQ/Loki e recursos cobrados.

## Entrega acadêmica

O registro dos testes da versão de entrega está em [VALIDACAO.md](VALIDACAO.md).

A entrega inclui vídeo de até 20 minutos, links dos cinco repositórios e este README como guia central. O vídeo demonstra requisições e segurança pelo Gateway, Function acionada e logs centralizados, dashboard em tempo real, MongoDB e cache.

O relatório PDF ou TXT enviado à faculdade deve conter nome do grupo, participantes e usernames do Discord, link da documentação, links dos repositórios e link do vídeo. Gravação, publicação do vídeo e envio do relatório são etapas de entrega independentes da execução do código.

## Referências

- [API HTTP do Loki](https://grafana.com/docs/loki/latest/reference/loki-http-api/)
- [Kubernetes local com kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
