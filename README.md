# hands-on-satubinha-k8s

Deploy do `satubinha-app` num cluster EKS real na AWS, com pipeline de qualidade e segurança, infra provisionada como código e entrega contínua via GitHub Actions. Parte da série **hands-on-satubinha**.

---

## Contexto

Projecto que fecha o ciclo da série **hands-on-satubinha**. A aplicação que correu em Docker Compose no `satubinha-app`, cuja infra foi provisionada no `satubinha-iac-terragrunt` e executada pelo Jenkins no `satubinha-jenkins`, corre agora num cluster Kubernetes gerido na AWS.

```
satubinha-app                  ←── aplicação (imagem)
satubinha-iac-terragrunt       ←── padrão IaC (Terragrunt DRY, OIDC, Checkov)
satubinha-jenkins              ←── padrão de segurança de imagens (Cosign, Trivy, tagging)
hands-on-satubinha-k8s         ←── este projecto — EKS + pipeline + deploy
```

---

## Visão geral

| Componente        | Tecnologia                                  |
|-------------------|---------------------------------------------|
| Cluster           | EKS (AWS)                                   |
| IaC               | Terraform ~> 1.10 + Terragrunt 0.67         |
| CI/CD             | GitHub Actions                              |
| Autenticação      | OIDC — sem credenciais estáticas            |
| Secrets           | SSM Parameter Store + IRSA                  |
| Deploy            | kubectl apply directo                       |
| Migrations        | Flyway (Kubernetes Job)                     |
| Imagens           | Chainguard                                  |
| Qualidade         | SonarCloud + Jest + Supertest               |
| Segurança imagens | Trivy + Cosign                              |
| Segurança IaC     | Checkov                                     |
| State backend     | S3 com lockfile nativo                      |

---

## Arquitectura

```
GitHub (push main)
      │
      ▼
GitHub Actions
      │
      ├── SonarCloud (quality gate)
      ├── Trivy (scan de código)
      ├── ECR check → build → Cosign sign → push
      ├── environment check → terragrunt run-all apply (se necessário)
      └── kubectl apply
            │
            ▼
      EKS Cluster
            │
      ┌─────┴──────┐
      │            │
   Job migrate   Deployments
   (Flyway)      (api + front)
      │            │
      └─────┬──────┘
            │
      PersistentVolume
      (PostgreSQL)
```

---

## Estrutura do projecto

```
hands-on-satubinha-k8s/
├── .github/
│   └── workflows/
│       ├── pipeline-dev.yml         # push main → auto-deploy
│       ├── pipeline-staging.yml     # manual dispatch
│       └── pipeline-prod.yml        # manual + aprovação obrigatória
├── environments/
│   ├── dev/
│   │   ├── network/
│   │   │   └── terragrunt.hcl      # VPC, subnets públicas/privadas, IGW, NAT GW
│   │   ├── eks/
│   │   │   └── terragrunt.hcl      # control plane, node group, IRSA roles
│   │   └── app-infra/
│   │       └── terragrunt.hcl      # ECR repos, SSM secrets
│   ├── staging/
│   │   ├── network/terragrunt.hcl
│   │   ├── eks/terragrunt.hcl
│   │   └── app-infra/terragrunt.hcl
│   └── prod/
│       ├── network/terragrunt.hcl
│       ├── eks/terragrunt.hcl
│       └── app-infra/terragrunt.hcl
├── modules/
│   ├── aws-eks/                    # EKS control plane + OIDC provider
│   ├── aws-eks-nodegroup/          # Node group + IAM Role
│   └── aws-ecr/                   # ECR repos + lifecycle policies
├── k8s/
│   ├── dev/
│   │   ├── deployment-api.yaml
│   │   ├── deployment-front.yaml
│   │   ├── job-migrate.yaml        # Flyway — restartPolicy: Never
│   │   ├── service.yaml
│   │   ├── ingress.yaml            # AWS ALB controller
│   │   ├── configmap.yaml          # variáveis de ambiente por ambiente
│   │   └── secret.yaml             # referência SSM via IRSA
│   ├── staging/
│   └── prod/
├── scripts/
│   └── check-environment.sh       # valida infra e cluster antes do deploy
├── root.hcl                       # backend S3, provider AWS, tags comuns
├── .checkov.yaml                  # supressões documentadas
├── .pre-commit-config.yaml
└── README.md
```

---

## Terragrunt — 3 layers

Padrão `root.hcl`, `dependency` blocks e `mock_outputs` igual ao `satubinha-iac-terragrunt`.

```
network
    │
    ├─────────────────────┐
    ▼                     ▼
  eks                  (vpc_id, subnet_ids)
    │                     │
    └──────────┬───────────┘
               ▼
           app-infra
```

O Terragrunt garante automaticamente a ordem de apply:

1. `network` — VPC, subnets públicas/privadas, IGW, NAT Gateway
2. `eks` — control plane, node group, IRSA roles
3. `app-infra` — ECR repos, SSM secrets

| Layer      | Recursos                                          | Quando muda               |
|------------|---------------------------------------------------|---------------------------|
| network    | VPC, Subnets, IGW, NAT Gateway                    | Raramente                 |
| eks        | EKS control plane, Node group, IRSA               | Raramente                 |
| app-infra  | ECR repos, SSM secrets                            | A cada nova configuração  |

---

## Arquitectura de rede por ambiente

Cada ambiente tem a sua própria VPC completamente isolada:

| Ambiente | VPC CIDR      | Subnets públicas    | Subnets privadas    |
|----------|---------------|---------------------|---------------------|
| dev      | `10.0.0.0/16` | `10.0.1.0/24`       | `10.0.10.0/24`      |
| staging  | `10.1.0.0/16` | `10.1.1.0/24`       | `10.1.10.0/24`      |
| prod     | `10.2.0.0/16` | `10.2.1.0/24`       | `10.2.10.0/24`      |

Os nodes EKS correm nas subnets privadas. O ALB Ingress expõe as aplicações pelas subnets públicas.

---

## Pipeline — ordem de execução

```
push main
    │
    ▼
1. checkout + lint
    │
    ▼
2. SonarCloud → quality gate (bloqueia se falhar)
    │
    ▼
3. Trivy → scan de código
    │
    ▼
4. ECR check → imagem já existe?
    ├── sim → verifica assinatura Cosign → avança
    └── não → build → Cosign sign → push (tag vX.Y-<sha>-stable)
    │
    ▼
5. environment check
    ├── terragrunt state list → infra existe?
    │       └── não → terragrunt run-all apply
    └── kubectl get nodes → cluster acessível?
    │
    ▼
6. kubectl apply (manifests do ambiente)
```

### Comportamento por ambiente

| Evento              | Dev              | Staging                        | Prod                            |
|---------------------|------------------|--------------------------------|---------------------------------|
| Push para main      | auto-apply       | não dispara                    | não dispara                     |
| workflow_dispatch   | plan/apply       | plan/apply                     | plan/apply                      |
| Aprovação manual    | Não              | Não                            | **Sim — GitHub Environment**    |

---

## Segurança

- **IRSA** — pods acedem ao SSM e ECR com IAM Role própria, sem credenciais estáticas
- **OIDC** — GitHub Actions autentica na AWS sem credenciais estáticas
- **IMDSv2 obrigatório** — protecção contra SSRF nos nodes
- **EBS encriptado** — disco dos nodes encriptado em todos os ambientes
- **Cosign key-based** — imagem assinada após push, verificada antes do deploy
- **Trivy** — bloqueia pipeline com CVEs CRITICAL ou HIGH
- **Checkov** — scan de segurança IaC em cada run do pipeline
- **Aprovação manual em prod** — GitHub Environments com required reviewers
- **Nodes em subnets privadas** — sem exposição directa à internet
- **S3 TLS obrigatório** — bucket de state rejeita ligações não encriptadas

---

## Testes

**Framework:** Jest + Supertest

**Cobertura mínima:** 80% de linhas em `src/`

**Relatório:** LCOV → SonarCloud

```
tests/
├── health.test.js    # testa GET /health
└── db.test.js        # testa conectividade com mock DB
```

O SonarCloud bloqueia o pipeline se o quality gate falhar — testes e cobertura são gates obrigatórios, não opcionais.

---

## Custo estimado (dev, quando ligado)

| Recurso          | Custo/hora |
|------------------|------------|
| EKS control plane | ~$0.10    |
| EC2 node t3.medium | ~$0.04   |
| NAT Gateway      | ~$0.045    |
| **Total activo** | **~$0.19/hora** |

Destróis o cluster quando não estás a desenvolver:

```bash
cd environments/dev/eks
terragrunt destroy

cd environments/dev/network
terragrunt destroy
```

---

## Como usar

### Pré-requisitos

- Terraform >= 1.10
- Terragrunt >= 0.67
- AWS CLI configurado
- kubectl instalado
- Cosign instalado
- Bucket S3 `hands-on-satubinha-tfstate` existente
- OIDC Provider configurado (via `foundation/` do `satubinha-iac-terragrunt`)

### Primeira execução

```bash
# 1. Provisionar a infra
cd environments/dev/network && terragrunt apply
cd environments/dev/eks && terragrunt apply
cd environments/dev/app-infra && terragrunt apply

# 2. Configurar kubeconfig
aws eks update-kubeconfig --name hands-on-satubinha-dev --region us-east-1

# 3. Validar cluster
kubectl get nodes

# 4. Deploy da aplicação
kubectl apply -f k8s/dev/
```

A partir daí o pipeline GitHub Actions trata de tudo automaticamente em cada push para `main`.

### Destruir por ordem inversa

```bash
kubectl delete -f k8s/dev/

cd environments/dev/app-infra && terragrunt destroy
cd environments/dev/eks && terragrunt destroy
cd environments/dev/network && terragrunt destroy
```

---

## O que vem dos projectos anteriores

| Padrão                          | Origem                     |
|---------------------------------|----------------------------|
| Cosign sign + verify            | satubinha-jenkins          |
| Trivy scan                      | satubinha-jenkins          |
| Tag `vX.Y-<sha>-stable`         | satubinha-jenkins          |
| ECR skip-build logic            | satubinha-jenkins          |
| Terragrunt DRY + root.hcl       | satubinha-iac-terragrunt   |
| OIDC sem credenciais estáticas  | satubinha-iac-terragrunt   |
| Checkov no pipeline IaC         | satubinha-iac-terragrunt   |
| Flyway migrations               | satubinha-app              |
| Chainguard images               | satubinha-app              |
| Healthchecks                    | satubinha-app              |

---

## O que não entra neste projecto

- ArgoCD / GitOps
- Prometheus / Grafana
- Helm
- External DNS / Route 53
- RDS
- Jenkins
- Container Structure Tests (Trivy + Cosign cobrem o mesmo)
- Node groups separados (system/workload)
- Multi-AZ node group

---

## Decisões técnicas

**Porque kubectl apply directo e não ArgoCD?**
O GitOps é o próximo passo natural da série. Introduzir ArgoCD aqui adicionaria uma camada de complexidade que obscurece o que se pretende demonstrar: o ciclo completo de infra + pipeline + deploy no EKS. O ArgoCD entra numa iteração futura quando o foco for especificamente GitOps.

**Porque PostgreSQL container + PersistentVolume e não RDS?**
O RDS adicionaria ~$25-50/mês de custo mínimo permanente. Um PersistentVolume num EBS encriptado serve o mesmo propósito para um ambiente de estudo, sem custo adicional e com o mesmo padrão de persistência.

**Porque SSM + IRSA e não Kubernetes Secrets?**
Kubernetes Secrets são base64, não encriptação. IRSA permite que cada pod tenha uma IAM Role própria com acesso mínimo ao SSM — zero credenciais estáticas nos manifests, zero risco de leak via `kubectl get secret`.

**Porque Flyway como Kubernetes Job e não init container?**
Um Job tem `restartPolicy: Never` e registo de execução permanente — consegues ver o histórico de migrations com `kubectl get jobs`. Um init container corre sempre que o pod reinicia, sem histórico isolado. O padrão Job reflecte o que se faz em ambientes reais.

**Porque NAT Gateway e não instância NAT?**
Os nodes EKS correm em subnets privadas e precisam de acesso à internet para pull de imagens e actualizações. O NAT Gateway é gerido pela AWS, sem manutenção. Para um lab com custo por hora, a diferença de preço é irrelevante.

---

## Roadmap

- [ ] Provisionar EKS com Terragrunt (3 layers)
- [ ] Modules: aws-eks, aws-eks-nodegroup, aws-ecr
- [ ] Manifests K8s: deployment-api, deployment-front, job-migrate, service, ingress, configmap, secret
- [ ] ALB Ingress controller
- [ ] IRSA para acesso ao SSM e ECR
- [ ] Testes Jest + Supertest com cobertura 80%
- [ ] SonarCloud — quality gate no pipeline
- [ ] Trivy — scan de código e imagem
- [ ] Cosign — sign + verify antes do deploy
- [ ] Pipeline dev (auto), staging (manual), prod (manual + aprovação)
- [ ] check-environment.sh — valida infra e cluster antes do deploy
- [ ] Testes end-to-end — deploy validado em dev, staging e prod
- [ ] README completo

---

## Série hands-on-satubinha

| Projecto | Descrição | Relação | Estado |
|---|---|---|---|
| [satubinha-app](https://github.com/fabricio-f5/satubinha-app) | App fullstack com Docker Compose, Chainguard, Flyway | — | ✅ |
| [satubinha-iac-terragrunt](https://github.com/fabricio-f5/hands-on-satubinha-iac-terragrunt) | Infra AWS multi-ambiente com Terraform + Terragrunt | infra repo | ✅ |
| [satubinha-jenkins](https://github.com/fabricio-f5/hands-on-satubinha-jenkins) | Plataforma de execução de infra self-hosted | pipeline repo | ✅ |
| **satubinha-k8s** | EKS + GitHub Actions + deploy contínuo | fecha o ciclo | 🔲 em curso |