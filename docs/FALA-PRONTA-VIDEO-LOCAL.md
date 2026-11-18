# Fala pronta para o video - Fase 4

Duracao sugerida: 12 a 18 minutos. Leia com naturalidade. Nao e necessario decorar.

## Links para deixar abertos

1. README: https://github.com/GabrielaMatheus/FCG-Orchestration
2. Terraform Azure: https://github.com/GabrielaMatheus/FCG-Orchestration/blob/main/infra/azure/main.tf
3. Kubernetes Azure: https://github.com/GabrielaMatheus/FCG-Orchestration/tree/main/k8s/overlays/azure
4. Pipeline UsersAPI: https://github.com/GabrielaMatheus/FCG-UsersAPI/blob/main/.github/workflows/ci-cd.yml
5. Pipeline CatalogAPI: https://github.com/GabrielaMatheus/FCG-CatalogAPI/blob/main/.github/workflows/ci-cd.yml
6. Evidencias: https://github.com/GabrielaMatheus/FCG-Orchestration/blob/main/VALIDACAO-FASE4.md
7. Swagger Users: http://localhost:8000/users-swagger/swagger/index.html
8. Swagger Catalog: http://localhost:8000/catalog-swagger/swagger/index.html
9. Grafana: http://localhost:3000
10. Prometheus: http://localhost:9090
11. OpenSearch: http://localhost:9200/_cluster/health

## Abertura

"Ola, meu nome e Gabriela Matheus e vou apresentar o Tech Challenge da Fase 4 do FIAP Cloud Games. Este e o mesmo projeto iniciado nas fases anteriores. Ele comecou como uma aplicacao unica e foi evoluido para microsservicos com usuarios, catalogo, pagamentos, notificacoes, gateway e mensageria."

"Nesta fase, o objetivo foi preparar a solucao para nuvem, acrescentar persistencia NoSQL, cache distribuido, busca avancada e uma pipeline de integracao e entrega continua."

## Arquitetura

Abra o README e mostre o diagrama.

"O Kong e a porta de entrada. A UsersAPI cuida de cadastro, login e biblioteca. A CatalogAPI cuida dos jogos, avaliacoes, cache e pesquisa. A PaymentsAPI processa compras. O RabbitMQ transporta eventos e a NotificationsFunction trata notificacoes."

"Os dados transacionais foram preparados para PostgreSQL. As avaliacoes usam MongoDB porque aceitam metadata flexivel. O Redis guarda temporariamente consultas frequentes. O Elasticsearch, representado localmente pelo OpenSearch compativel, fornece busca aproximada e ordenacao por relevancia."

## Infraestrutura como codigo

Abra `infra/azure/main.tf`.

"O Terraform cria a infraestrutura sem configuracao manual: AKS, Container Registry, PostgreSQL, Cosmos DB com API MongoDB, Redis, Elastic Cloud e Key Vault. O AKS executaria os containers e o Key Vault protegeria os segredos."

Abra `k8s/overlays/azure`.

"Os manifests Kubernetes usam duas replicas, health checks e rolling update com indisponibilidade maxima igual a zero. Isso foi preparado para atualizar as APIs sem derrubar o sistema."

"A ativacao da assinatura Azure foi bloqueada durante a verificacao da forma de pagamento. Por transparencia, nenhum recurso cloud sera apresentado como executado. A infraestrutura esta implementada e validada como codigo, enquanto a demonstracao funcional sera feita localmente com Docker."

## Containers locais

Abra o Docker Desktop e mostre os containers em execucao.

"No ambiente local, cada componente esta isolado em um container. Estao em execucao Kong, as tres APIs, RabbitMQ, MongoDB, Redis, OpenSearch, Prometheus, Grafana e Azurite."

No PowerShell, entre na pasta de orquestracao e execute:

```powershell
cd "C:\Users\gabri\OneDrive\Documentos\FCG-Microservices\FCG-Orchestration"
.\scripts\Run-Demo-Fase4.ps1
```

Quando a senha for solicitada, digite a senha local combinada. Ela nao aparecera na tela.

Depois do resultado, diga:

"O primeiro teste mostra que uma rota protegida rejeita chamadas sem JWT. Em seguida, o catalogo e consultado duas vezes. A segunda resposta apresenta X-Cache igual a HIT e leva menos tempo, comprovando o Redis."

"A busca recebe Avetura, escrito incorretamente, e retorna Aventura Espacial com um score. Isso demonstra tolerancia a erro e ordenacao por relevancia."

"O teste tambem cria uma avaliacao com metadata flexivel e depois consulta o mesmo identificador. O resultado MongoReviewPersisted igual a True comprova a gravacao no MongoDB."

## Swagger e observabilidade

Abra os Swagger de Users e Catalog.

"O Swagger documenta os endpoints das APIs. As rotas passam pelo Kong e as operacoes protegidas exigem JWT."

Abra Grafana, Prometheus e a saude do OpenSearch.

"Prometheus coleta metricas, Grafana disponibiliza paineis e OpenSearch apresenta o estado do mecanismo de pesquisa. Esses componentes permitem acompanhar saude, desempenho e falhas."

## CI/CD e seguranca

Abra os dois workflows `ci-cd.yml`.

"Cada pipeline restaura dependencias, compila, executa testes, constroi uma imagem Docker identificada pelo commit, verifica vulnerabilidades com Trivy, envia a imagem ao Azure Container Registry e realiza rolling update no AKS."

"O login no Azure foi preparado com OIDC e Managed Identity, evitando uma senha permanente do Azure no GitHub. As credenciais de aplicacao foram previstas no Key Vault e os manifests apenas referenciam o secret fcg-runtime."

## Evidencias e encerramento

Abra `VALIDACAO-FASE4.md`.

"Foram aprovados quatro testes da UsersAPI e sete testes da CatalogAPI. As imagens Docker foram construidas e a solucao integrada foi validada com JWT, MongoDB, Redis, busca fuzzy, OpenSearch, Prometheus e Grafana."

"Assim, a Fase 4 entrega a evolucao do FIAP Cloud Games com persistencia poliglota, ganho de desempenho por cache, pesquisa avancada, seguranca, containers, Kubernetes, infraestrutura como codigo e CI/CD. A execucao demonstrada foi local devido ao bloqueio externo da assinatura, e essa limitacao esta registrada de forma transparente na documentacao. Obrigada."
