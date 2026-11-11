# Validacao tecnica - Fase 4

Ultima revisao local: 2026-11-11.

## Testes automatizados

| Projeto | Resultado local |
| --- | --- |
| CatalogAPI | 7/7 aprovados em Release |
| UsersAPI | 4/4 aprovados em Release |

O CatalogAPI usa PostgreSQL, `MongoDB.Driver`, `IDistributedCache` com Redis e a API REST do Elasticsearch. Os testes de sincronizacao confirmam indexacao em create/update e remocao no delete.

## Verificacoes estaticas

- [x] Workflows incluem build, testes, imagem versionada, Trivy, ACR e deploy no AKS.
- [x] Azure Login dos workflows usa OIDC e Managed Identity, sem client secret.
- [x] Manifests usam rolling update com `maxUnavailable: 0` em producao.
- [x] Kong possui rota `/search` protegida por JWT.
- [x] Segredos de producao sao referenciados pelo Secret `fcg-runtime`.
- [x] Terraform inclui AKS, ACR, PostgreSQL, Cosmos DB MongoDB, Managed Redis, Elastic Cloud, Key Vault e OIDC.
- [x] Script de teste verifica cache HIT e fuzzy search.
- [x] Deploy inicial tambem publica a imagem da PaymentsAPI.
- [x] `terraform init` com AzureRM 4.81.0, Elastic EC 0.13.1 e Random 3.9.1.
- [x] `terraform validate`: configuracao valida.
- [x] Kustomize Azure renderizado com 15 recursos.
- [x] 19 arquivos YAML dos workflows e manifests Kubernetes analisados sem erro.
- [x] `docker compose config`: valido.
- [x] `Provision-Azure.ps1`, `Deploy-Azure.ps1` e `Destroy-Azure.ps1` analisados sem erro de sintaxe.
- [ ] Build real das imagens Docker: Docker Desktop foi iniciado, mas o engine nao ficou disponivel sem interacao do usuario.

## Validacoes que dependem das contas do grupo

- [ ] Login em uma assinatura Azure ativa.
- [ ] API key de organizacao do Elastic Cloud criada.
- [ ] `terraform plan` revisado e `terraform apply` autorizado.
- [ ] `Deploy-Azure.ps1` executado contra o AKS criado.
- [ ] Variables cadastradas nos dois repositorios GitHub.
- [ ] Pipelines executadas em `main`.
- [ ] Teste integrado executado contra o IP do Azure Load Balancer.
- [ ] Evidencias gravadas para o pitch.
- [ ] `terraform destroy` executado depois da gravacao.
