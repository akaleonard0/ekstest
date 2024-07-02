module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description = "Access to cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default_node_group_1 = {
      name              = "ng-prd-api"
      instance_types    = ["t3.medium"]
      ami_type          = "AL2_x86_64"
      enable_monitoring = true
      capacity_type     = "SPOT"

      iam_role_additional_policies = {
        SecretsManagerReadWrite  = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonSSMReadOnlyAccess  = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 40
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      max_size     = 10
      desired_size = 1

      labels = {
        "role" = "api"
      }
    }

    default_node_group_3 = {
      name              = "ng-prd-dados"
      instance_types    = ["t3.xlarge"]
      ami_type          = "AL2_x86_64"
      enable_monitoring = true
      capacity_type     = "ON_DEMAND"

      iam_role_additional_policies = {
        SecretsManagerReadWrite  = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonSSMReadOnlyAccess  = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 40
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      max_size     = 10
      desired_size = 1

      labels = {
        "app"                          = "airflow"
        "role"                         = "dados"
        "hub.jupyter.org/node-purpose" = "core"
        "app-ss"                       = "superset"
      }
    }
  }

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${var.account_number}:role/eks-management-role"
      username = "eks-management-role"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${var.account_number}:user/user-xxxxxx-${var.env}"
      username = "user-adm-rankmyapp-${var.env}"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [var.account_number]

  tags = {
    Environment = "prd"
    Terraform   = "true"
  }
}

output "cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
