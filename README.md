
# README: Implantação da Aplicação de Teste no Amazon EKS

Este guia fornece instruções passo a passo para implantar uma aplicação de Teste no Amazon EKS usando um pipeline CI/CD com AWS CodePipeline, CodeBuild e ECR.

## Pré-requisitos

1. **Conta AWS**: Certifique-se de ter acesso a uma conta AWS com permissões suficientes.
2. **AWS CLI**: Instale e configure a AWS CLI.
3. **Terraform**: Instale o Terraform para provisionamento de infraestrutura.
4. **kubectl**: Instale o kubectl para interagir com seu cluster EKS.

## Instruções de Configuração

### 1. Clone o Repositório

Clone o repositório contendo o código de infraestrutura e aplicação.

```sh
git clone <url-do-repositorio>
cd <diretorio-do-repositorio>
```

### 2. Configuração da Infraestrutura com Terraform

#### a. Crie `terraform.tfvars`

Crie um arquivo `terraform.tfvars` com as variáveis necessárias.

```sh
cat <<EOF > terraform.tfvars
aws_account_id = "ID-AWS"
aws_region = "us-east-1"
cluster_name = "cluster-app"
vpc_id = "vpc-xxxxx" # Substitua pelo ID do seu VPC
public_subnets = ["subnet-xxxxx", "subnet-xxxxx"] # Substitua pelos IDs dos seus subnets públicos
private_subnets = ["subnet-xxxxx", "subnet-xxxxx"] # Substitua pelos IDs dos seus subnets privados
EOF
```

#### b. Inicialize e Aplique o Terraform:
#### Todos os arquivos TF precisam ser alterados ID-AWS para seu ID.

```sh
terraform init
terraform apply -auto-approve
```

Isso provisionará os recursos AWS necessários, incluindo o cluster EKS, funções IAM, políticas, repositório CodeCommit e CodePipeline.

### 3. Faça Push do Código da Aplicação para o CodeCommit

Crie um novo repositório CodeCommit e faça push do seu código de aplicação.

```sh
git remote add codecommit <url-do-repositorio-codecommit>
git push codecommit main
```

### 4. Configuração do BuildSpec

Certifique-se de que seu arquivo `buildspec.yml` no diretório raiz do repositório esteja configurado da seguinte forma:

```yaml
version: 0.2
run-as: root

phases:
  install:
    commands:
      - echo Instalando dependências do aplicativo...
      - curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl  
      - chmod +x ./kubectl
      - mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
      - echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
      - echo 'Verificando a versão do kubectl'
      - kubectl version --short --client

  pre_build:
    commands:
      - echo Logando no Amazon EKS...
      - aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $AWS_CLUSTER_NAME
      - echo Verificando configuração 
      - kubectl config view --minify
      - echo Verificando acesso do kubectl
      - echo Logando no Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
      - docker pull $REPOSITORY_URI:$IMAGE_TAG

  build:
    commands:
      - echo Build iniciado em `date`
      - echo Construindo a imagem Docker...          
      - docker build --cache-from $IMAGE_REPO_NAME:$IMAGE_TAG -t $IMAGE_REPO_NAME:$IMAGE_TAG -f app/Dockerfile app/.
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG 

  post_build:
    commands:
      - echo Build completado em `date`
      - echo Enviando a imagem Docker...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - echo Enviando a última imagem para o cluster
      - aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $AWS_CLUSTER_NAME
      - kubectl config use-context arn:aws:eks:us-east-1:405427360740:cluster/$AWS_CLUSTER_NAME
      - kubectl apply -f k8s/deployment.yaml
      - kubectl apply -f k8s/service.yaml
      - kubectl rollout restart -f k8s/deployment.yaml
```

### 5. Configure o ConfigMap `aws-auth`

Certifique-se de que a função IAM usada pelo CodeBuild tenha as permissões necessárias no cluster EKS. Atualize o ConfigMap `aws-auth`:
Substitua o ID-AWS pel seu ID.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ID_AWS:role/codebuild-role
      username: build
      groups:
        - system:masters
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::ID-AWS:role/ng-prd-api-eks-node-group-20240702001022949700000003
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::ID-AWS:role/ng-prd-dados-eks-node-group-20240702001022948900000002
      username: system:node:{{EC2PrivateDNSName}}
```

### 6. Acessando o Serviço pelo IP Externo

Para acessar seu serviço pelo IP externo, siga os passos abaixo:

1. Obtenha o nome do serviço LoadBalancer:
   ```sh
   kubectl get svc -n <namespace>
   ```

2. Verifique o External-IP atribuído ao serviço:
   ```sh
   kubectl describe svc <nome-do-servico> -n <namespace>
   ```

3. Acesse sua aplicação via navegador ou curl utilizando o External-IP:
   ```sh
   curl http://<External-IP>
   ```

Agora você configurou e implantou com sucesso a aplicação de Teste no Amazon EKS utilizando uma pipeline CI/CD com CodePipeline e CodeBuild.
