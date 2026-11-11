# Guia Azure passo a passo

Este guia foi escrito para quem nunca usou Azure, Terraform ou Kubernetes. Faca uma etapa por vez. Nao envie senha, numero de cartao, API key nem codigo de verificacao para o GitHub, para o grupo ou para este chat.

## O que ja esta pronto

O codigo ja esta preparado para Azure. Tambem ja estao instalados, dentro da pasta local do projeto, o Terraform e o Azure CLI. O assistente `scripts/Provision-Azure.ps1` faz o trabalho tecnico de preparar o plano e criar a infraestrutura. O `scripts/Deploy-Azure.ps1` compila as imagens, envia ao Azure e publica os microsservicos no AKS.

Voce precisa fazer somente as acoes que exigem a sua identidade, um aceite de custo ou uma informacao secreta.

## Parte 1 - conferir sua conta Azure

1. Abra o navegador.
2. Entre em <https://portal.azure.com>.
3. Entre com a sua conta Microsoft. Se ainda nao houver conta Azure, escolha a opcao para criar uma.
4. A Microsoft pode pedir telefone, documento e cartao. Preencha somente no site oficial da Microsoft. O projeto e o assistente nao precisam ver esses dados.
5. Na barra de busca do portal, escreva `Assinaturas`.
6. Clique em **Assinaturas**.
7. Verifique se existe uma assinatura com o estado **Ativa**.

Se nao existir uma assinatura ativa, pare aqui. A infraestrutura nao pode ser criada ate a Azure liberar uma assinatura.

## Parte 2 - criar um aviso de custo

1. Ainda no Portal do Azure, procure `Gerenciamento de Custos + Cobrança`.
2. Abra **Gerenciamento de Custos** e depois **Orçamentos**.
3. Clique em **Adicionar**.
4. Use o nome `aviso-fcg`.
5. Escolha um valor que voce aceita gastar.
6. Cadastre alertas em 50%, 80% e 100%, usando o seu e-mail.
7. Salve.

Importante: o orçamento manda avisos, mas nao desliga os recursos automaticamente. Depois de gravar as evidencias da entrega, destrua o ambiente seguindo a Parte 9.

## Parte 3 - criar a conta Elastic Cloud e a chave

1. Abra <https://cloud.elastic.co/registration>.
2. Crie a conta ou entre em uma conta existente.
3. No menu da organizacao, abra **Organization**, **API Keys**.
4. Clique para criar uma API key.
5. Use o nome `fcg-terraform`.
6. Copie a chave e guarde temporariamente em um lugar privado. Ela costuma ser mostrada uma unica vez.
7. Nao cole essa chave neste chat e nao a coloque em nenhum arquivo do Git.

Essa chave autoriza o Terraform a criar o Elasticsearch gerenciado dentro da infraestrutura Azure da Elastic.

## Parte 4 - abrir o Docker Desktop que ja esta instalado

O Docker Desktop foi instalado e usado nas fases anteriores. Nao e necessario criar outra conta nem instalar uma segunda copia.

1. Clique no menu Iniciar do Windows.
2. Digite `Docker Desktop`.
3. Abra o programa.
4. Se aparecer um contrato, leia e aceite para continuar.
5. Espere ate o Docker informar que esta funcionando. O icone da baleia deve ficar estavel, sem mensagem de inicializacao.
6. Deixe o Docker Desktop aberto.

Neste computador, a instalacao existente do Docker Desktop 4.82 apresentou um erro interno ao criar sockets temporarios. Se a janela mostrar **An unexpected error occurred**, nao escolha **Reset to factory defaults**, porque isso pode apagar dados locais. Faca assim:

1. Clique em **Quit**.
2. Abra <https://www.docker.com/products/docker-desktop/>.
3. Baixe a atualizacao atual do Docker Desktop para Windows.
4. Abra o atualizador baixado. Ele atualiza a instalacao existente; nao cria um segundo Docker.
5. Quando o Windows perguntar se permite alteracoes, clique em **Sim**.
6. Conclua a atualizacao e, se o instalador pedir, reinicie o computador.
7. Abra o Docker Desktop novamente e espere a baleia ficar pronta.

## Parte 5 - executar o assistente de infraestrutura

1. Clique no menu Iniciar.
2. Digite `PowerShell`.
3. Abra **Windows PowerShell**.
4. Copie o comando abaixo inteiro, cole no PowerShell e aperte Enter:

```powershell
Set-Location 'C:\Users\gabri\OneDrive\Documentos\FCG-Microservices\FCG-Orchestration'
```

5. Copie este segundo comando e aperte Enter:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Provision-Azure.ps1
```

6. Se uma janela do navegador abrir, entre na sua conta Microsoft e confirme o login do Azure CLI.
7. O PowerShell pedira o e-mail do administrador do FCG. Digite o e-mail e aperte Enter.
8. O PowerShell pedira a `Elastic Cloud API key`. Cole a chave criada na Parte 3 e aperte Enter. Nada aparecera na tela enquanto voce cola; isso e proposital.
9. Espere o Terraform mostrar o plano. Ele ainda nao tera criado os recursos.
10. Leia o aviso de custo. Se estiver de acordo, digite exatamente `APLICAR` e aperte Enter. Qualquer outra palavra cancela sem criar a infraestrutura.
11. Espere terminar. A criacao dos servicos gerenciados pode demorar bastante.

Se aparecer um erro dizendo que ja existe um Cosmos DB Free Tier, abra `infra\azure\terraform.tfvars`, troque `cosmos_enable_free_tier = true` por `cosmos_enable_free_tier = false` e execute o assistente novamente.

## Parte 6 - publicar o sistema no AKS

Quando a Parte 5 terminar com sucesso, use a mesma janela do PowerShell e execute:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Deploy-Azure.ps1
```

O script vai:

1. entrar no AKS;
2. compilar UsersAPI, CatalogAPI e PaymentsAPI;
3. enviar as imagens ao Azure Container Registry;
4. copiar os segredos do Key Vault sem mostrá-los;
5. publicar os componentes no Kubernetes;
6. esperar todos os componentes ficarem prontos;
7. mostrar o servico `kong` e o endereco publico.

Se houver erro, copie apenas a mensagem de erro. Antes de enviar, confirme que ela nao contem API key, senha ou connection string.

## Parte 7 - colocar as variaveis no GitHub

Depois que o Azure estiver criado, rode no PowerShell:

```powershell
& 'C:\Users\gabri\OneDrive\Documentos\New project 3\.tools\terraform\terraform.exe' -chdir=infra/azure output github_repository_variables
```

Para cada repositorio `FCG-UsersAPI` e `FCG-CatalogAPI`:

1. Abra o repositorio no GitHub.
2. Clique em **Settings**.
3. Clique em **Environments**.
4. Crie o ambiente `production`.
5. Volte a **Settings**, abra **Secrets and variables**, depois **Actions**.
6. Abra a aba **Variables**.
7. Crie uma variable para cada nome mostrado pelo comando: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, `AKS_CLUSTER_NAME`, `ACR_NAME` e `ACR_LOGIN_SERVER`.
8. Crie `ACR_REPOSITORY` com `fcg-users-api` no UsersAPI e `fcg-catalog-api` no CatalogAPI.

Esses valores identificam os recursos, mas nao sao senhas. A autenticacao da pipeline usa OIDC e nao precisa de client secret.

## Parte 8 - evidencias e entrega

1. Guarde uma imagem dos pods prontos: `kubectl -n fcg get pods`.
2. Guarde uma imagem do endereco do Kong: `kubectl -n fcg get service kong`.
3. Demonstre cadastro/login, catalogo, cache HIT, avaliacao e busca aproximada.
4. Grave o pitch usando `docs/ROTEIRO-PITCH-FASE4.md`.
5. Preencha nomes, Discord, URLs dos repositorios, URL publica e link do video no relatorio.
6. Antes de enviar, confira `docs/CHECKLIST-FASE4.md` linha por linha.

## Parte 9 - apagar o ambiente e parar novas cobrancas

Depois de gravar todas as evidencias, execute:

```powershell
Set-Location 'C:\Users\gabri\OneDrive\Documentos\FCG-Microservices\FCG-Orchestration'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Destroy-Azure.ps1
```

O assistente pedira novamente a API key do Elastic e exigira que voce digite `DESTRUIR`. Depois, confira no Portal do Azure se o grupo `rg-fcg-prod` desapareceu e no Elastic Cloud se o deployment foi removido.

## Quando pedir ajuda

Pode pedir ajuda a qualquer momento. Envie uma captura de tela ou a mensagem de erro, mas esconda senhas, connection strings, API keys, numero de cartao e codigos de verificacao.
