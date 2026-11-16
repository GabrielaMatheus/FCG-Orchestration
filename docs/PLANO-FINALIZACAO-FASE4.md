# Plano de finalizacao - Fase 4

Siga nesta ordem no dia da entrega.

## 1. Ativar as contas

- Gabriela conclui a assinatura Azure com pagamento conforme o uso e confirma que aparece uma assinatura ativa no Portal.
- Gabriela entra ou cria a conta Elastic Cloud e gera uma API key de organizacao.
- Nao crie recursos manualmente no Portal.

## 2. Criar o ambiente

- Executar `scripts/Provision-Azure.ps1`.
- Revisar o `terraform plan` antes de confirmar `APLICAR`.
- Executar `scripts/Deploy-Azure.ps1`.
- Anotar o IP publico do Service `kong`.

## 3. Ligar o CI/CD

- Cadastrar no Environment `production` dos repositorios UsersAPI e CatalogAPI as variables produzidas pelo Terraform.
- Executar um push controlado em `main` e acompanhar build, testes, Trivy, ACR e rolling update no AKS.

## 4. Validar e guardar evidencias

- Executar `scripts/Test-Fase4.ps1` contra o IP do Azure.
- Registrar pods do AKS e servicos gerenciados no Portal.
- Registrar `X-Cache: HIT`, busca fuzzy por relevancia e avaliacao persistida no MongoDB/Cosmos DB.
- Registrar a pipeline e o deploy sem indisponibilidade.

## 5. Fechar a entrega

- Gabriela informa nomes completos e usernames do Discord do grupo.
- Gabriela grava o video de ate 25 minutos seguindo `ROTEIRO-PITCH-FASE4.md` e publica no YouTube nao listado ou Google Drive.
- Preencher o relatorio com IP, data e link do video.
- Conferir todos os links e enviar no portal da FIAP.

## 6. Parar a cobranca

- Depois de salvar todas as evidencias, executar `scripts/Destroy-Azure.ps1`.
- Confirmar que o Resource Group e o deployment do Elastic Cloud foram removidos.
