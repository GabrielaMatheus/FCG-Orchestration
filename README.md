# FIAP Cloud Games - Fase 4

Solucao cloud-native em microsservicos .NET 8 no Microsoft Azure, com AKS, Azure Container Registry, PostgreSQL Flexible Server, Cosmos DB for MongoDB, Azure Managed Redis, Elastic Cloud, Azure Key Vault, RabbitMQ, Kong e CI/CD por GitHub Actions.

Este e o mesmo FIAP Cloud Games iniciado na Fase 1 e evoluido nas Fases 2 e 3. A Fase 4 nao recria o sistema: preserva dominio, APIs, pagamentos, RabbitMQ, Kong e a NotificationsFunction e acrescenta infraestrutura gerenciada, busca avancada e entrega continua. A linha do tempo completa esta em [docs/HISTORICO-DO-PROJETO.md](docs/HISTORICO-DO-PROJETO.md).

## Requisitos atendidos

| Requisito | Implementacao |
| --- | --- |
| Kubernetes gerenciado | Azure Kubernetes Service com node pool gerenciado e autoscaling |
| Registry privado | Azure Container Registry privado |
| Exposicao externa | Kong por Service `LoadBalancer` do Azure |
| NoSQL | Cosmos DB for MongoDB e driver oficial `MongoDB.Driver`; avaliacoes com metadata flexivel |
| Cache distribuido | Azure Managed Redis e `IDistributedCache`; header `X-Cache` demonstra HIT/MISS |
| Busca avancada | Elastic Cloud hospedado no Azure, `multi_match`, fuzziness `AUTO` e score de relevancia |
| Sincronizacao do indice | Create/Update/Delete no CatalogAPI e reconciliacao no startup |
| CI/CD | Build, testes, imagem versionada, Trivy, ACR e rolling update no AKS |
| Segredos | Azure Key Vault sincronizado com Kubernetes Secret e Secrets Store CSI Driver |
| Deploy sem downtime | Duas replicas, readiness/liveness probes e `maxUnavailable: 0` |

## Arquitetura

```text
Internet
  -> Azure Load Balancer
    -> Kong
      -> UsersAPI (2 replicas) -> Azure PostgreSQL
      -> CatalogAPI (2 replicas)
           -> Azure PostgreSQL
           -> Cosmos DB for MongoDB
           -> Azure Managed Redis
           -> Elastic Cloud on Azure
      -> RabbitMQ -> PaymentsAPI / NotificationsFunction

GitHub main -> Actions -> testes -> Docker -> Trivy -> ACR -> rolling update AKS
Azure Key Vault -> Kubernetes Secret + CSI rotation -> pods
RabbitMQ -> Azure NotificationsFunction (componente serverless preservado da Fase 3)
```

O PostgreSQL substitui o SQLite em producao para que as replicas compartilhem persistencia transacional. Cosmos DB armazena as avaliacoes flexiveis via protocolo MongoDB; Redis nao e fonte de verdade; Elasticsearch e um indice reconstruivel.

A `FCG-NotificationsFunction` nao foi reescrita porque ja utiliza Azure Functions com .NET 8 e possui Bicep proprio. A implantacao principal desta fase concentra os workloads em AKS pedidos pelo novo documento; a Function continua como componente serverless independente do fluxo de eventos.

## Repositorios

- [UsersAPI](https://github.com/GabrielaMatheus/FCG-UsersAPI)
- [CatalogAPI](https://github.com/GabrielaMatheus/FCG-CatalogAPI)
- [PaymentsAPI](https://github.com/GabrielaMatheus/FCG-PaymentsAPI)
- [NotificationsFunction](https://github.com/GabrielaMatheus/FCG-NotificationsFunction)
- [Orchestration](https://github.com/GabrielaMatheus/FCG-Orchestration)

## Producao no Azure

Pre-requisitos: assinatura Azure ativa, Azure CLI autenticada, Terraform 1.9+, kubectl, Docker Desktop e uma conta Elastic Cloud com API key de organizacao.

> AKS, VMs, PostgreSQL, Managed Redis e Elastic Cloud geram custos. Sempre revise o `terraform plan`. Para um ambiente academico, grave as evidencias e execute `terraform destroy` assim que terminar.

### 1. Provisionar a infraestrutura

Para quem nunca usou Azure, siga primeiro o [guia bem detalhado](docs/GUIA-AZURE-PASSO-A-PASSO.md). O assistente abaixo faz login, pede a chave Elastic sem exibi-la, gera e valida o plano e exige a confirmacao `APLICAR` antes de criar recursos pagos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Provision-Azure.ps1
```

Os comandos manuais equivalentes sao:

```powershell
az login
az account show
cd infra/azure
Copy-Item terraform.tfvars.example terraform.tfvars
# Edite apenas subscription id e e-mail no arquivo copiado.
$env:TF_VAR_elastic_cloud_api_key='<ELASTIC_CLOUD_API_KEY>'
terraform init
terraform fmt -check
terraform validate
terraform plan -out fase4.tfplan
terraform apply fase4.tfplan
```

O Terraform cria resource group, rede, AKS, ACR, PostgreSQL Flexible Server, Cosmos DB for MongoDB, Azure Managed Redis, Elastic Cloud on Azure, Key Vault e a identidade OIDC usada pelos workflows. Senhas sao geradas aleatoriamente e armazenadas no Key Vault.

O `terraform.tfstate` contem valores sensiveis, embora estejam marcados como sensitive. Ele esta ignorado pelo Git; em trabalho compartilhado, use backend remoto criptografado.

Se a assinatura ja tiver um Cosmos DB Free Tier, altere `cosmos_enable_free_tier = false` antes do plan.

### 2. Primeiro deploy no AKS

Na raiz do repositorio de orquestracao:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Deploy-Azure.ps1
```

O script usa os outputs do Terraform, configura o contexto AKS, compila e envia UsersAPI, CatalogAPI e PaymentsAPI ao ACR, le os valores do Key Vault sem exibi-los, cria o Secret `fcg-runtime`, configura a rotacao pelo CSI Driver, aplica `k8s/overlays/azure` e aguarda todos os rollouts. Os arquivos temporarios de segredo sao removidos no bloco `finally`.

Para pular o build depois que as imagens ja existirem:

```powershell
.\scripts\Deploy-Azure.ps1 -SkipImageBuild
```

Para obter o endereco publico:

```powershell
kubectl -n fcg get service kong
```

### 3. Configurar o CI/CD no GitHub

Crie o Environment `production` nos repositorios UsersAPI e CatalogAPI. Cadastre estas Repository Variables usando `terraform output github_repository_variables`:

| Variable | Origem |
| --- | --- |
| `AZURE_CLIENT_ID` | output `github_actions_client_id` |
| `AZURE_TENANT_ID` | output `azure_tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | output `azure_subscription_id` |
| `AZURE_RESOURCE_GROUP` | output `resource_group_name` |
| `AKS_CLUSTER_NAME` | output `cluster_name` |
| `ACR_NAME` | output `acr_name` |
| `ACR_LOGIN_SERVER` | output `acr_login_server` |
| `ACR_REPOSITORY` | `fcg-users-api` ou `fcg-catalog-api` |

Um push em `main` executa restore, build, testes, build da imagem com tag do SHA, scan Trivy, push no ACR e rolling update apenas do Deployment correspondente. O Azure Login usa OIDC e nao exige client secret.

## Desenvolvimento local

Copie `.env.example` para `.env` e preencha os valores locais; nunca versione `.env`.
Defina uma senha forte em `OPENSEARCH_INITIAL_ADMIN_PASSWORD`; a imagem atual do OpenSearch exige esse valor mesmo com o plugin de seguranca desabilitado apenas no ambiente local.

```powershell
docker compose config
docker compose up -d --build
```

| Componente | URL local |
| --- | --- |
| Gateway | `http://localhost:8000` |
| Swagger Users | `http://localhost:8000/users-swagger/swagger/index.html` |
| Swagger Catalog | `http://localhost:8000/catalog-swagger/swagger/index.html` |
| OpenSearch local compativel | `http://localhost:9200` |
| Grafana | `http://localhost:3000` |
| Prometheus | `http://localhost:9090` |

O container OpenSearch existe apenas para desenvolvimento e usa a mesma API REST necessaria aos testes. Producao utiliza Elasticsearch gerenciado no Elastic Cloud, hospedado em `azure-eastus2` com HTTPS.

## Validacao funcional

Depois de cadastrar ou manter o jogo inicial `Aventura Espacial`, execute:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Fase4.ps1 `
  -BaseUrl http://localhost:8000 `
  -AdminEmail '<email>' `
  -AdminPassword '<senha>'
```

O script autentica, consulta o catalogo duas vezes, exige `X-Cache: HIT` na segunda chamada, busca `Avetura` e valida o resultado fuzzy em ordem decrescente de score.

## Seguranca

- Nenhuma credencial real ou connection string e versionada em appsettings, workflows ou YAMLs.
- GitHub usa federacao OIDC com uma Azure Managed Identity.
- AKS recebe permissao `AcrPull`; GitHub recebe somente `AcrPush` e acesso de escrita no AKS.
- Key Vault guarda senhas e connection strings e o CSI Driver faz rotacao automatica.
- PostgreSQL usa subnet delegada privada e TLS.
- Cosmos DB aceita a subnet do AKS; Redis e Elastic Cloud usam TLS e autenticacao.
- A pipeline bloqueia imagens com vulnerabilidades HIGH/CRITICAL corrigiveis.
- Containers das APIs removem capabilities Linux e impedem privilege escalation.

## Encerrar o ambiente e parar custos

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Destroy-Azure.ps1
```

Confirme no Portal do Azure que `rg-fcg-prod` desapareceu e no Elastic Cloud que o deployment nao existe mais.

## Entrega academica

- Checklist tecnico: [docs/CHECKLIST-FASE4.md](docs/CHECKLIST-FASE4.md)
- Roteiro do pitch: [docs/ROTEIRO-PITCH-FASE4.md](docs/ROTEIRO-PITCH-FASE4.md)
- Roteiro de contingencia para demonstracao local: [docs/ROTEIRO-PITCH-FASE4-LOCAL.md](docs/ROTEIRO-PITCH-FASE4-LOCAL.md)
- Evidencias locais verificadas: [docs/EVIDENCIAS-LOCAIS-FASE4.md](docs/EVIDENCIAS-LOCAIS-FASE4.md)
- Modelo do relatorio: [docs/RELATORIO-ENTREGA-FASE4.md](docs/RELATORIO-ENTREGA-FASE4.md)
- Evidencias de validacao: [VALIDACAO-FASE4.md](VALIDACAO-FASE4.md)
- Guia Azure para iniciantes: [docs/GUIA-AZURE-PASSO-A-PASSO.md](docs/GUIA-AZURE-PASSO-A-PASSO.md)
- Plano curto para o dia da entrega: [docs/PLANO-FINALIZACAO-FASE4.md](docs/PLANO-FINALIZACAO-FASE4.md)
- Historico das Fases 1 a 4: [docs/HISTORICO-DO-PROJETO.md](docs/HISTORICO-DO-PROJETO.md)

Nomes do grupo, usernames do Discord, URL final do ambiente e link do video precisam ser preenchidos pelo grupo antes da entrega.
