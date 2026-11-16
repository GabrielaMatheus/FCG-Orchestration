# Checklist de conformidade - Fase 4

## Infraestrutura gerenciada e portabilidade

- [x] Evolucao feita sobre os cinco repositorios e o fluxo assincrono das Fases 2 e 3.
- [x] PaymentsAPI, RabbitMQ, Kong e NotificationsFunction preservados.
- [x] Terraform para Resource Group, VNet e Azure Kubernetes Service.
- [x] Node pool gerenciado com autoscaling.
- [x] Azure Container Registry privado.
- [x] Kong exposto por Service `LoadBalancer`.
- [x] Overlay Kustomize separado para Azure.
- [x] Readiness/liveness probes, duas replicas e rolling update sem indisponibilidade.
- [ ] `terraform apply` executado na assinatura do grupo e IP externo registrado.

## Persistencia poliglota e performance

- [x] Azure Cosmos DB for MongoDB usado para avaliacoes e metadata flexivel.
- [x] Driver oficial `MongoDB.Driver`.
- [x] Azure Managed Redis via `IDistributedCache`.
- [x] Cache de listagem e consulta por ID com expiracao de cinco minutos.
- [x] Invalidacao em create/update/delete.
- [x] Header `X-Cache` para demonstrar HIT/MISS.
- [x] PostgreSQL Flexible Server para dados transacionais compartilhados.

## Busca avancada

- [x] Elastic Cloud gerenciado e hospedado no Microsoft Azure previsto no Terraform.
- [x] Indice independente do banco relacional.
- [x] Comunicacao HTTPS autenticada pela API REST oficial do Elasticsearch.
- [x] Indexacao em create/update/delete.
- [x] Reconciliacao de todos os jogos na inicializacao.
- [x] Endpoint `/search` protegido por JWT.
- [x] Fuzziness `AUTO`, nome com boost e retorno por relevancia.
- [x] Teste demonstrativo com termo digitado incorretamente.

## CI/CD e GitOps

- [x] Workflow GitHub Actions para UsersAPI.
- [x] Workflow GitHub Actions para CatalogAPI.
- [x] Restore, build e testes automatizados.
- [x] Imagens com tag imutavel do SHA e tag `latest`.
- [x] Scan Trivy HIGH/CRITICAL.
- [x] Push ao ACR.
- [x] Deploy no AKS e `kubectl rollout status`.
- [x] OIDC Azure sem senha persistente.
- [ ] Variables configuradas no GitHub Environment `production`.
- [ ] Push em `main` demonstrado ao vivo.

## Seguranca e segredos

- [x] Credenciais removidas de appsettings, launch settings e YAMLs.
- [x] Azure Key Vault criado pelo Terraform.
- [x] Secret `fcg-runtime` gerado em runtime.
- [x] Secrets Store CSI Driver habilitado com rotacao.
- [x] Arquivos temporarios de segredos removidos no `finally`.
- [x] PostgreSQL em subnet privada.
- [x] TLS para PostgreSQL, Redis, Cosmos DB e Elastic Cloud.
- [ ] Backend remoto e criptografado configurado para o Terraform state, se o grupo compartilhar o state.

## Entregaveis

- [x] Historico das Fases 1 a 4 documentado para demonstrar a continuidade do projeto.
- [x] Codigo e integracoes atualizados.
- [x] Terraform e manifestos Kubernetes.
- [x] Pipelines `.yml`.
- [x] README detalhado.
- [x] Roteiro de video de ate 25 minutos.
- [x] Modelo de relatorio.
- [ ] Nomes e Discord do grupo preenchidos.
- [x] Links finais dos repositorios confirmados.
- [ ] Video publicado no YouTube ou Drive e link preenchido.
